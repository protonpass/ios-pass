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
import Factory
import SwiftUI

protocol CreateEditLoginViewModelDelegate: AnyObject {
    func createEditLoginViewModelWantsToGenerateAlias(options: AliasOptions,
                                                      creationInfo: AliasCreationLiteInfo,
                                                      delegate: AliasCreationLiteInfoDelegate)

    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: GeneratePasswordViewModelDelegate)
    func createEditLoginViewModelWantsToOpenSettings()
}

final class CreateEditLoginViewModel: BaseCreateEditItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var canAddOrEdit2FAURI = true
    @Published private(set) var isAlias = false // `Username` is an alias or a custom one
    @Published var title = ""
    @Published var username = ""
    @Published var password = ""
    @Published var totpUri = ""
    @Published var urls: [IdentifiableObject<String>] = [.init(value: "")]
    @Published var invalidURLs = [String]()
    @Published var note = ""

    @Published var isShowingNoCameraPermissionView = false
    @Published var isShowingCodeScanner = false
    @Published private(set) var loading = false

    /// Proton account email address
    let emailAddress: String

    private let aliasRepository = resolve(\SharedRepositoryContainer.aliasRepository)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    /// The original associated alias item
    private var aliasItem: SymmetricallyEncryptedItem?

    private var aliasOptions: AliasOptions?
    private(set) var aliasCreationLiteInfo: AliasCreationLiteInfo?

    weak var createEditLoginViewModelDelegate: CreateEditLoginViewModelDelegate?

    private var hasNoUrls: Bool {
        urls.isEmpty || (urls.count == 1 && urls[0].value.isEmpty)
    }

    var isAutoFilling: Bool {
        if case let .create(_, type) = mode,
           case let .login(_, _, autofill) = type {
            return autofill
        }
        return false
    }

    private let checkCameraPermission = resolve(\SharedUseCasesContainer.checkCameraPermission)

    override var isSaveable: Bool { !title.isEmpty && !hasEmptyCustomField }

    override init(mode: ItemMode,
                  upgradeChecker: UpgradeCheckerProtocol,
                  vaults: [Vault]) throws {
        let userData = resolve(\SharedDataContainer.userData)
        emailAddress = userData.addresses.first?.email ?? ""
        try super.init(mode: mode,
                       upgradeChecker: upgradeChecker,
                       vaults: vaults)
        Publishers
            .CombineLatest($title, $username)
            .combineLatest($password)
            .combineLatest($totpUri)
            .combineLatest($urls)
            .combineLatest($note)
            .dropFirst(mode.isEditMode ? 1 : 3)
            .sink(receiveValue: { [weak self] _ in
                self?.didEditSomething = true
            })
            .store(in: &cancellables)

        $selectedVault
            .eraseToAnyPublisher()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if self.aliasOptions != nil {
                    self.aliasOptions = nil
                    self.aliasCreationLiteInfo = nil
                    self.isAlias = false
                    self.username = ""
                }
            }
            .store(in: &cancellables)
    }

    override func bindValues() {
        switch mode {
        case let .edit(itemContent):
            if case let .login(data) = itemContent.contentData {
                title = itemContent.name
                username = data.username
                password = data.password
                totpUri = data.totpUri
                if !data.urls.isEmpty {
                    urls = data.urls.map { .init(value: $0) }
                }
                note = itemContent.note

                Task { @MainActor [weak self] in
                    guard let self else { return }
                    do {
                        self.aliasItem = try await self.itemRepository.getAliasItem(email: username)
                        self.isAlias = self.aliasItem != nil
                    } catch {
                        self.logger.error(error)
                        self.router
                            .display(element: .displayErrorBanner(error))
                    }
                }
            }

        case let .create(_, type):
            if case let .login(title, url, _) = type {
                self.title = title ?? ""
                urls = [url ?? ""].map { .init(value: $0) }
            }

            Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    self.canAddOrEdit2FAURI = try await self.upgradeChecker.canHaveMoreLoginsWith2FA()
                } catch {
                    self.logger.error(error)
                    self.router.display(element: .displayErrorBanner(error))
                }
            }
        }
    }

    override func itemContentType() -> ItemContentType { .login }

    override func saveButtonTitle() -> String {
        guard case let .create(_, type) = mode,
              case let .login(_, _, autofill) = type,
              autofill else {
            return super.saveButtonTitle()
        }
        return "Create & AutoFill".localized
    }

    override func generateItemContent() -> ItemContentProtobuf {
        let sanitizedUrls = urls.compactMap { URLUtils.Sanitizer.sanitize($0.value) }
        let logInData = ItemContentData.login(.init(username: username,
                                                    password: password,
                                                    totpUri: totpUri,
                                                    urls: sanitizedUrls))
        return ItemContentProtobuf(name: title,
                                   note: note,
                                   itemUuid: UUID().uuidString,
                                   data: logInData,
                                   customFields: customFieldUiModels.map(\.customField))
    }

    override func generateAliasCreationInfo() -> AliasCreationInfo? {
        guard isAlias, let aliasCreationLiteInfo else { return nil }

        return .init(prefix: aliasCreationLiteInfo.prefix,
                     suffix: aliasCreationLiteInfo.suffix,
                     mailboxIds: aliasCreationLiteInfo.mailboxes.map(\.ID))
    }

    override func generateAliasItemContent() -> ItemContentProtobuf? {
        guard isAlias, aliasCreationLiteInfo != nil else { return nil }
        return .init(name: title,
                     note: "Alias of login item \"%@\"".localized(title),
                     itemUuid: UUID().uuidString,
                     data: .alias,
                     customFields: [])
    }

    override func additionalEdit() async throws {
        // Remove alias item if necessary
        if let aliasEmail = aliasItem?.item.aliasEmail, !isAlias {
            try await itemRepository.deleteAlias(email: aliasEmail)
        }
        // Create new alias item if applicable
        else if let aliasCreationInfo = generateAliasCreationInfo(),
                let aliasItemContent = generateAliasItemContent() {
            try await itemRepository.createAlias(info: aliasCreationInfo,
                                                 itemContent: aliasItemContent,
                                                 shareId: selectedVault.shareId)
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

    func openCodeScanner() {
        Task { @MainActor [weak self] in
            guard let authorized = await self?.checkCameraPermission(),
                  authorized else {
                self?.isShowingNoCameraPermissionView = true
                return
            }
            self?.isShowingCodeScanner = true
        }
    }

    func removeAlias() {
        aliasCreationLiteInfo = nil
        username = ""
        isAlias = false
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
        createEditLoginViewModelDelegate?.createEditLoginViewModelWantsToOpenSettings()
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
        isAlias = true
    }
}
