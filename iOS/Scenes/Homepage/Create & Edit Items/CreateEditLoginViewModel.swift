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
import SwiftUI

@MainActor
protocol CreateEditLoginViewModelDelegate: AnyObject {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: AliasCreationLiteInfoDelegate)

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: GeneratePasswordViewModelDelegate)
}

@MainActor
final class CreateEditLoginViewModel: BaseCreateEditItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var canAddOrEdit2FAURI = true
    @Published var title = ""
    @Published var username = ""
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

    /// Proton account email address
    let emailAddress: String

    private let aliasRepository = resolve(\SharedRepositoryContainer.aliasRepository)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    private var aliasOptions: AliasOptions?
    @Published private var aliasCreationLiteInfo: AliasCreationLiteInfo?
    var isAlias: Bool { aliasCreationLiteInfo != nil }

    weak var createEditLoginViewModelDelegate: CreateEditLoginViewModelDelegate?

    private let checkCameraPermission = resolve(\SharedUseCasesContainer.checkCameraPermission)
    private let sanitizeTotpUriForEditing = resolve(\SharedUseCasesContainer.sanitizeTotpUriForEditing)
    private let sanitizeTotpUriForSaving = resolve(\SharedUseCasesContainer.sanitizeTotpUriForSaving)
    private let userDataProvider = resolve(\SharedDataContainer.userDataProvider)
    private let getPasswordStrength = resolve(\SharedUseCasesContainer.getPasswordStrength)

    var isSaveable: Bool { !title.isEmpty && !hasEmptyCustomField }

    override init(mode: ItemMode,
                  upgradeChecker: UpgradeCheckerProtocol,
                  vaults: [Vault]) throws {
        emailAddress = try userDataProvider.getUnwrappedUserData().addresses.first?.email ?? ""
        try super.init(mode: mode,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults)
        setUp()
    }

    override func bindValues() {
        switch mode {
        case let .edit(itemContent):
            if case let .login(data) = itemContent.contentData {
                title = itemContent.name
                username = data.username
                password = data.password
                originalTotpUri = data.totpUri
                totpUri = sanitizeTotpUriForEditing(data.totpUri)
                allowedAndroidApps = data.allowedAndroidApps
                if !data.urls.isEmpty {
                    urls = data.urls.map { .init(value: $0) }
                }
                note = itemContent.note
            }

        case let .create(_, type):
            if case let .login(title, url, note, _) = type {
                self.title = title ?? ""
                self.note = note ?? ""
                urls = [url ?? ""].map { .init(value: $0) }
            }

            // We only show upsell button when in create mode
            // because we want to let users access their data in edit mode
            // even when they've reached limitations
            Task { @MainActor [weak self] in
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

    override func itemContentType() -> ItemContentType { .login }

    override func saveButtonTitle() -> String {
        guard case let .create(_, type) = mode,
              case let .login(_, _, _, autofill) = type,
              autofill else {
            return super.saveButtonTitle()
        }
        return #localized("Create & AutoFill")
    }

    @MainActor
    override func generateItemContent() -> ItemContentProtobuf? {
        do {
            let sanitizedUrls = urls.compactMap { URLUtils.Sanitizer.sanitize($0.value) }
            let sanitizedTotpUri = try sanitizeTotpUriForSaving(originalUri: originalTotpUri,
                                                                editedUri: totpUri)
            let logInData = ItemContentData.login(.init(username: username,
                                                        password: password,
                                                        totpUri: sanitizedTotpUri,
                                                        urls: sanitizedUrls,
                                                        allowedAndroidApps: allowedAndroidApps))
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

    override func additionalEdit() async throws {
        // Create new alias item if applicable
        if let aliasCreationInfo = generateAliasCreationInfo(),
           let aliasItemContent = generateAliasItemContent() {
            try await itemRepository.createAlias(info: aliasCreationInfo,
                                                 itemContent: aliasItemContent,
                                                 shareId: selectedVault.shareId)
        }
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

    func generateAlias() {
        if let aliasOptions, let aliasCreationLiteInfo {
            createEditLoginViewModelDelegate?
                .createEditLoginViewModelWantsToGenerateAlias(options: aliasOptions,
                                                              creationInfo: aliasCreationLiteInfo,
                                                              delegate: self)
        } else {
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.loading = false }
                do {
                    self.loading = true
                    let aliasOptions = try await self.aliasRepository
                        .getAliasOptions(shareId: self.selectedVault.shareId)
                    if let firstSuffix = aliasOptions.suffixes.first,
                       let firstMailbox = aliasOptions.mailboxes.first {
                        var prefix = PrefixUtils.generatePrefix(fromTitle: title)
                        if prefix.isEmpty {
                            prefix = String.random(allowedCharacters: [.lowercase, .digit], length: 5)
                        }

                        self.aliasOptions = aliasOptions
                        self.aliasCreationLiteInfo = .init(prefix: prefix,
                                                           suffix: firstSuffix,
                                                           mailboxes: [firstMailbox])
                        self.generateAlias()
                    }
                } catch {
                    self.router.display(element: .displayErrorBanner(error))
                }
            }
        }
    }

    func useRealEmailAddress() {
        username = emailAddress
    }

    func generatePassword() {
        createEditLoginViewModelDelegate?.createEditLoginViewModelWantsToGeneratePassword(self)
    }

    func pasteTotpUriFromClipboard() {
        totpUri = UIPasteboard.general.string ?? ""
    }

    func pastePasswordFromClipboard() {
        password = UIPasteboard.general.string ?? ""
    }

    func openCodeScanner() {
        Task { @MainActor [weak self] in
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
        username = ""
    }

    func handleScanResult(_ result: Result<String, Error>, customField: CustomFieldUiModel? = nil) {
        switch result {
        case let .success(scanResult):
            if let customField {
                customFieldEdited(customField, content: scanResult)
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
}

// MARK: - SetUP & Utils

private extension CreateEditLoginViewModel {
    func setUp() {
        bindValues()

        $selectedVault
            .eraseToAnyPublisher()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if aliasOptions != nil {
                    aliasOptions = nil
                    aliasCreationLiteInfo = nil
                    username = ""
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
        username = info.aliasAddress
    }
}
