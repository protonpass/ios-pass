//
// CreateEditLoginViewModel.swift
// Proton Pass - Created on 05/08/2022.
// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.

import AVFoundation
import Client
import CodeScanner
import Combine
import Core
import Entities
import Factory
import Macro
import Screens
import SwiftUI

@MainActor
protocol CreateEditLoginViewModelDelegate: AnyObject {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: any AliasCreationLiteInfoDelegate)

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: any GeneratePasswordViewModelDelegate)
}

@MainActor
final class CreateEditLoginViewModel: BaseCreateEditItemViewModel, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var canAddOrEdit2FAURI = true
    @Published var title = ""
    @Published private(set) var passkeys: [Passkey] = []

    @Published var emailOrUsername = ""
    @Published var email = ""
    @Published var username = ""
    @Published private(set) var emailUsernameExpanded = false

    @Published var password = ""
    @Published private(set) var passwordStrength: PasswordStrength?
    private var originalTotpUri = ""
    @Published var totpUri = ""
    @Published private(set) var totpUriErrorMessage = ""
    @Published var urls: [IdentifiableObject<String>] = [.init(value: "")]
    @Published var invalidURLs = [String]()
    @Published var note = ""

    @Published var isShowingNoCameraPermissionView = false
    @Published var isShowingCodeScanner = false
    @Published private(set) var loading = false

    private var allowedAndroidApps: [AllowedAndroidApp] = []

    @Published private(set) var passkeyRequest: PasskeyCredentialRequest?
    private var passkeyResponse: CreatePasskeyResponse?

    /// Proton account email address
    private(set) var emailAddress: String = ""

    private let aliasRepository = resolve(\SharedRepositoryContainer.aliasRepository)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    private var aliasOptions: AliasOptions?
    @Published private var aliasCreationLiteInfo: AliasCreationLiteInfo?
    var isAlias: Bool { aliasCreationLiteInfo != nil }

    private let checkCameraPermission = resolve(\SharedUseCasesContainer.checkCameraPermission)
    private let sanitizeTotpUriForEditing = resolve(\SharedUseCasesContainer.sanitizeTotpUriForEditing)
    private let sanitizeTotpUriForSaving = resolve(\SharedUseCasesContainer.sanitizeTotpUriForSaving)
    private let getPasswordStrength = resolve(\SharedUseCasesContainer.getPasswordStrength)
    private let createPasskey = resolve(\SharedUseCasesContainer.createPasskey)
    private let validateEmail = resolve(\SharedUseCasesContainer.validateEmail)
    private let getSharedPreferences = resolve(\SharedUseCasesContainer.getSharedPreferences)

    override var isSaveable: Bool {
        super.isSaveable && !title.isEmpty && !hasEmptyCustomField
    }

    weak var delegate: (any CreateEditLoginViewModelDelegate)?

    override init(mode: ItemMode,
                  upgradeChecker: any UpgradeCheckerProtocol,
                  vaults: [Share]) throws {
        try super.init(mode: mode,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults)
        emailAddress = userManager.currentActiveUser.value?.addresses.first?.email ?? ""

        setUp()
    }

    override func bindValues() {
        defer {
            emailUsernameExpanded = emailUsernameExpanded || getSharedPreferences().alwaysShowUsernameField
        }

        switch mode {
        case let .clone(itemContent), let .edit(itemContent):
            if case let .login(data) = itemContent.contentData {
                title = itemContent.name

                emailOrUsername = data.email.isEmpty ? data.username : data.email
                emailUsernameExpanded = !data.email.isEmpty && !data.username.isEmpty
                email = data.email
                username = data.username

                password = data.password
                originalTotpUri = data.totpUri
                totpUri = sanitizeTotpUriForEditing(data.totpUri)
                allowedAndroidApps = data.allowedAndroidApps
                passkeys = data.passkeys
                if !data.urls.isEmpty {
                    urls = data.urls.map { .init(value: $0) }
                }
                note = itemContent.note
            }

        case let .create(_, type):
            if case let .login(title, url, note, totpUri, _, request) = type {
                passkeyRequest = request
                self.title = title ?? request?.relyingPartyIdentifier ?? ""
                self.note = note ?? ""
                username = request?.userName ?? ""
                if let totpUri {
                    self.totpUri = sanitizeTotpUriForEditing(totpUri)
                }
                urls = [url ?? request?.relyingPartyIdentifier ?? ""].map { .init(value: $0) }
            }

            // We only show upsell button when in create mode
            // because we want to let users access their data in edit mode
            // even when they've reached limitations
            Task { [weak self] in
                guard let self else { return }
                do {
                    canAddOrEdit2FAURI = try await upgradeChecker.canHaveMoreLoginsWith2FA()
                } catch {
                    logger.error(error)
                    router.display(element: .displayErrorBanner(error))
                }
            }
        }
    }

    override var itemContentType: ItemContentType { .login }

    override func saveButtonTitle() -> String {
        guard case let .create(_, type) = mode,
              case let .login(_, _, _, _, autofill, _) = type,
              autofill else {
            return super.saveButtonTitle()
        }
        return #localized("Create & AutoFill")
    }

    @MainActor
    override func generateItemContent() async -> ItemContentProtobuf? {
        do {
            let sanitizedUrls = urls.compactMap { URLUtils.Sanitizer.sanitize($0.value) }
            let sanitizedTotpUri = try sanitizeTotpUriForSaving(originalUri: originalTotpUri,
                                                                editedUri: totpUri)
            var passkeys = passkeys
            if let newPasskey = try await newPasskey() {
                passkeys.append(newPasskey.toPasskey)
            }

            var finalEmail = ""
            var finalUsername = ""

            if emailUsernameExpanded {
                finalEmail = email
                finalUsername = username
            } else {
                if validateEmail(email: emailOrUsername) {
                    finalEmail = emailOrUsername
                } else {
                    finalUsername = emailOrUsername
                }
            }

            let logInData = ItemContentData.login(.init(email: finalEmail,
                                                        username: finalUsername,
                                                        password: password,
                                                        totpUri: sanitizedTotpUri,
                                                        urls: sanitizedUrls,
                                                        allowedAndroidApps: allowedAndroidApps,
                                                        passkeys: passkeys))
            return ItemContentProtobuf(name: title,
                                       note: note,
                                       itemUuid: UUID().uuidString,
                                       data: logInData,
                                       customFields: customFieldUiModels.map(\.customField))
        } catch {
            totpUriErrorMessage = #localized("Invalid TOTP URI")
            return nil
        }
    }

    override func newPasskey() async throws -> CreatePasskeyResponse? {
        if let passkeyRequest, passkeyResponse == nil {
            passkeyResponse = try await createPasskey(passkeyRequest,
                                                      bundle: .main,
                                                      device: .current)
        }
        return passkeyResponse
    }

    override func generateAliasCreationInfo() -> AliasCreationInfo? {
        guard let aliasCreationLiteInfo else { return nil }

        return .init(prefix: aliasCreationLiteInfo.prefix,
                     suffix: aliasCreationLiteInfo.suffix,
                     mailboxIds: aliasCreationLiteInfo.mailboxes.map(\.ID))
    }

    override func generateAliasItemContent() -> ItemContentProtobuf? {
        guard isAlias else { return nil }
        return .init(name: title,
                     note: #localized("Alias of login item \"%@\"", title),
                     itemUuid: UUID().uuidString,
                     data: .alias,
                     customFields: [])
    }

    override func additionalEdit() async throws -> Bool {
        // Create new alias item if applicable
        let userId = try await userManager.getActiveUserId()
        guard let aliasCreationInfo = generateAliasCreationInfo(),
              let aliasItemContent = generateAliasItemContent() else { return false }
        try await itemRepository.createAlias(userId: userId,
                                             info: aliasCreationInfo,
                                             itemContent: aliasItemContent,
                                             shareId: selectedVault.shareId)
        return true
    }

    override func telemetryEventTypes() -> [TelemetryEventType] {
        if originalTotpUri.isEmpty, !totpUri.isEmpty {
            [.twoFaCreation]
        } else if totpUri != sanitizeTotpUriForEditing(originalTotpUri) {
            // The edited URI != the URI for editing
            [.twoFaUpdate]
        } else {
            []
        }
    }

    override func save() {
        if validateURLs() {
            super.save()
        }
    }

    func generateAlias() {
        Task { [weak self] in
            guard let self else { return }
            defer { self.loading = false }
            do {
                loading = true
                if aliasOptions == nil {
                    aliasOptions = try await aliasRepository.getAliasOptions(shareId: selectedVault.shareId)
                }
                if let aliasOptions,
                   let firstSuffix = aliasOptions.suffixes.first,
                   let firstMailbox = aliasOptions.mailboxes.first {
                    var prefix = PrefixUtils.generatePrefix(fromTitle: title)
                    if prefix.isEmpty {
                        prefix = String.random(allowedCharacters: [.lowercase, .digit], length: 5)
                    }

                    let info = AliasCreationLiteInfo(prefix: prefix,
                                                     suffix: firstSuffix,
                                                     mailboxes: [firstMailbox])
                    delegate?.createEditLoginViewModelWantsToGenerateAlias(options: aliasOptions,
                                                                           creationInfo: info,
                                                                           delegate: self)
                }
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func expandEmailAndUsername() {
        guard !emailUsernameExpanded else { return }
        defer { emailUsernameExpanded = true }
        guard emailOrUsername != email, emailOrUsername != username else { return }

        if validateEmail(email: emailOrUsername) {
            email = emailOrUsername
        } else {
            username = emailOrUsername
        }
    }

    func useRealEmailAddress() {
        if emailUsernameExpanded {
            email = emailAddress
        } else {
            emailOrUsername = emailAddress
        }
    }

    func generatePassword() {
        delegate?.createEditLoginViewModelWantsToGeneratePassword(self)
    }

    func pasteTotpUriFromClipboard() {
        totpUri = UIPasteboard.general.string ?? ""
    }

    func pastePasswordFromClipboard() {
        password = UIPasteboard.general.string ?? ""
    }

    func openCodeScanner() {
        Task { [weak self] in
            guard let self else { return }
            if await checkCameraPermission() {
                isShowingCodeScanner = true
            } else {
                isShowingNoCameraPermissionView = true
            }
        }
    }

    func removeAlias() {
        aliasCreationLiteInfo = nil
        email = ""
        emailOrUsername = ""
    }

    func handleScanResult(_ result: Result<String, any Error>, customField: CustomFieldUiModel? = nil) {
        switch result {
        case let .success(scanResult):
            if let customField {
                editCustomField(customField, update: .content(scanResult))
            } else {
                totpUri = scanResult
            }
        case let .failure(error):
            router.display(element: .displayErrorBanner(error))
        }
    }

    func openSettings() {
        router.navigate(to: .openSettings)
    }

    func validateURLs() -> Bool {
        invalidURLs = urls.map(\.value).compactMap { url in
            if url.isEmpty { return nil }
            if URLUtils.Sanitizer.sanitize(url) == nil {
                return url
            }
            return nil
        }
        return invalidURLs.isEmpty
    }

    func remove(passkey: Passkey) {
        passkeys.removeAll(where: { $0.keyID == passkey.keyID })
    }
}

// MARK: - SetUP & Utils

private extension CreateEditLoginViewModel {
    func setUp() {
        bindValues()

        $selectedVault
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                // Reset alias options after switching vault because
                // options are bound to vaults
                if aliasOptions != nil {
                    aliasOptions = nil
                    aliasCreationLiteInfo = nil
                    email = ""
                }
            }
            .store(in: &cancellables)

        $totpUri
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                totpUriErrorMessage = ""
            }
            .store(in: &cancellables)

        $password
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] passwordValue in
                guard let self else { return }
                passwordStrength = getPasswordStrength(password: passwordValue)
            }
            .store(in: &cancellables)

        if #available(iOS 17, *) {
            UsernameTip.enabled = true
        }
    }
}

// MARK: - GeneratePasswordViewModelDelegate

extension CreateEditLoginViewModel: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        self.password = password
    }
}

// MARK: - AliasCreationLiteInfoDelegate

extension CreateEditLoginViewModel: AliasCreationLiteInfoDelegate {
    func aliasLiteCreationInfo(_ info: AliasCreationLiteInfo) {
        aliasCreationLiteInfo = info
        if emailUsernameExpanded {
            email = info.aliasAddress
        } else {
            emailOrUsername = info.aliasAddress
        }
    }
}
