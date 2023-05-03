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
import SwiftOTP
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

    /// Proton account email address
    let emailAddress: String

    private let aliasRepository: AliasRepositoryProtocol

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

    override var isSaveable: Bool { !title.isEmpty }

    init(mode: ItemMode,
         itemRepository: ItemRepositoryProtocol,
         aliasRepository: AliasRepositoryProtocol,
         vaults: [Vault],
         preferences: Preferences,
         logManager: LogManager,
         emailAddress: String) throws {
        self.emailAddress = emailAddress
        self.aliasRepository = aliasRepository
        try super.init(mode: mode,
                       itemRepository: itemRepository,
                       vaults: vaults,
                       preferences: preferences,
                       logManager: logManager)
        Publishers
            .CombineLatest($title, $username)
            .combineLatest($password)
            .combineLatest($totpUri)
            .combineLatest($urls)
            .combineLatest($note)
            .dropFirst(mode.isEditMode ? 1 : 3)
            .sink(receiveValue: { [unowned self] _ in
                self.didEditSomething = true
            })
            .store(in: &cancellables)

        $vault
            .eraseToAnyPublisher()
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
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
        case .edit(let itemContent):
            if case .login(let data) = itemContent.contentData {
                self.title = itemContent.name
                self.username = data.username
                self.password = data.password
                self.totpUri = data.totpUri
                if !data.urls.isEmpty {
                    self.urls = data.urls.map { .init(value: $0) }
                }
                self.note = itemContent.note

                Task { @MainActor in
                    aliasItem = try await itemRepository.getAliasItem(email: username)
                    isAlias = aliasItem != nil
                }
            }

        case let .create(_, type):
            if case let .login(title, url, _) = type {
                self.title = title ?? ""
                self.urls = [url ?? ""].map { .init(value: $0) }
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
        return "Create & AutoFill"
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
                                   data: logInData)
    }

    override func generateAliasCreationInfo() -> AliasCreationInfo? {
        guard isAlias, let aliasCreationLiteInfo else { return nil }

        return .init(prefix: aliasCreationLiteInfo.prefix,
                     suffix: aliasCreationLiteInfo.suffix,
                     mailboxIds: aliasCreationLiteInfo.mailboxes.map { $0.ID })
    }

    override func generateAliasItemContent() -> ItemContentProtobuf? {
        guard isAlias, aliasCreationLiteInfo != nil else { return nil }
        return .init(name: title,
                     note: "Alias of login item \"\(title)\"",
                     itemUuid: UUID().uuidString,
                     data: .alias)
    }

    override func additionalEdit() async throws {
        // Remove alias item if necessary
        if let aliasEmail = aliasItem?.item.aliasEmail, !isAlias {
            try await itemRepository.deleteAlias(email: aliasEmail)
        }
    }

    func generateAlias() {
        if let aliasOptions, let aliasCreationLiteInfo {
            createEditLoginViewModelDelegate?
                .createEditLoginViewModelWantsToGenerateAlias(options: aliasOptions,
                                                              creationInfo: aliasCreationLiteInfo,
                                                              delegate: self)
        } else {
            Task { @MainActor in
                do {
                    delegate?.createEditItemViewModelWantsToShowLoadingHud()
                    let aliasOptions = try await aliasRepository.getAliasOptions(shareId: vault.shareId)
                    delegate?.createEditItemViewModelWantsToHideLoadingHud()
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
                        generateAlias()
                    }
                } catch {
                    delegate?.createEditItemViewModelWantsToHideLoadingHud()
                    delegate?.createEditItemViewModelDidFail(error)
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
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .denied, .restricted:
            isShowingNoCameraPermissionView.toggle()
        case .authorized:
            isShowingCodeScanner.toggle()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [unowned self] success in
                DispatchQueue.main.async {
                    if success {
                        self.isShowingCodeScanner.toggle()
                    } else {
                        self.isShowingNoCameraPermissionView.toggle()
                    }
                }
            }
        @unknown default:
            logger.trace("Unknown case")
        }
    }

    func removeAlias() {
        aliasCreationLiteInfo = nil
        username = ""
        isAlias = false
    }

    func handleScanResult(_ result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let successResult):
            totpUri = successResult.string
        case .failure(let error):
            delegate?.createEditItemViewModelDidFail(error)
        }
    }

    func openSettings() {
        createEditLoginViewModelDelegate?.createEditLoginViewModelWantsToOpenSettings()
    }

    func validateURLs() -> Bool {
        invalidURLs = urls.map { $0.value }.compactMap { url in
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
