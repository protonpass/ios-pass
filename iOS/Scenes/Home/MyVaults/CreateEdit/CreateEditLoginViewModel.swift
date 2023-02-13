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

import Client
import CodeScanner
import Combine
import Core
import SwiftOTP
import SwiftUI

protocol CreateEditLoginViewModelDelegate: AnyObject {
    func createEditLoginViewModelWantsToGenerateAlias(_ delegate: AliasCreationDelegate,
                                                      title: String)
    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: GeneratePasswordViewModelDelegate)
    func createEditLoginViewModelDidReceiveAliasCreationInfo()
    func createEditLoginViewModelWantsToCopy(text: String, bannerMessage: String)
}

final class CreateEditLoginViewModel: BaseCreateEditItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var isAlias = false // `Username` is an alias or a custom one
    @Published var title = ""
    @Published var username = ""
    @Published var password = ""
    @Published var isPasswordSecure = true // Password in clear text or not
    @Published var totpUri = "" {
        didSet {
            totpManager.bind(uri: totpUri)
        }
    }
    @Published var urls: [String] = [""]
    @Published var note = ""
    @Published private(set) var totpManager: TOTPManager

    /// The original associated alias item
    private var aliasItem: SymmetricallyEncryptedItem?
    /// The info to create new alias.
    private var aliasCreationInfo: AliasCreationInfo?

    private var cancellables = Set<AnyCancellable>()

    weak var createEditLoginViewModelDelegate: CreateEditLoginViewModelDelegate?

    private var hasNoUrls: Bool {
        urls.isEmpty || (urls.count == 1 && urls[0].isEmpty)
    }

    var isEmpty: Bool {
        title.isEmpty && username.isEmpty && password.isEmpty && hasNoUrls && note.isEmpty
    }

    var isAutoFilling: Bool {
        if case let .create(_, type) = mode,
           case let .login(_, _, autofill) = type {
            return autofill
        }
        return false
    }

    override var isSaveable: Bool {
        !title.isEmpty && !password.isEmpty
    }

    override init(mode: ItemMode,
                  itemRepository: ItemRepositoryProtocol,
                  preferences: Preferences,
                  logManager: LogManager) {
        self.totpManager = .init(logManager: logManager)
        super.init(mode: mode,
                   itemRepository: itemRepository,
                   preferences: preferences,
                   logManager: logManager)
        self.totpManager.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
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
                    self.urls = data.urls
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
                self.urls = [url ?? ""]
            }
        }
    }

    override func navigationBarTitle() -> String {
        switch mode {
        case .create:
            return "New login"
        case .edit:
            return "Edit login"
        }
    }

    override func itemContentType() -> ItemContentType { .login }

    override func generateItemContent() -> ItemContentProtobuf {
        let sanitizedUrls = urls.compactMap { URLUtils.Sanitizer.sanitize($0) }
        let logInData = ItemContentData.login(.init(username: username,
                                                    password: password,
                                                    totpUri: totpUri,
                                                    urls: sanitizedUrls))
        return ItemContentProtobuf(name: title,
                                   note: note,
                                   data: logInData)
    }

    override func additionalCreate() async throws {
        if let aliasCreationInfo {
            let aliasContent = ItemContentProtobuf(name: aliasCreationInfo.title,
                                                   note: aliasCreationInfo.note,
                                                   data: .alias)
            try await self.itemRepository.createAlias(info: aliasCreationInfo,
                                                      itemContent: aliasContent,
                                                      shareId: shareId)
        }
    }

    override func additionalEdit() async throws {
        // Remove alias item if necessary
        if let aliasEmail = aliasItem?.item.aliasEmail, !isAlias {
            try await itemRepository.deleteAlias(email: aliasEmail)
        }
    }

    func generateAlias() {
        createEditLoginViewModelDelegate?
            .createEditLoginViewModelWantsToGenerateAlias(self, title: title)
    }

    func generatePassword() {
        createEditLoginViewModelDelegate?.createEditLoginViewModelWantsToGeneratePassword(self)
    }

    func removeAlias() {
        aliasCreationInfo = nil
        username = ""
        isAlias = false
    }

    func copyTotpCode() {
        if let code = totpManager.totpData?.code {
            let message = "Two Factor Authentication code copied"
            createEditLoginViewModelDelegate?
                .createEditLoginViewModelWantsToCopy(text: code,
                                                     bannerMessage: message)
        }
    }

    func handleScanResult(_ result: Result<ScanResult, ScanError>) {
        switch result {
        case .success(let successResult):
            totpUri = successResult.string
        case .failure(let error):
            delegate?.createEditItemViewModelDidFail(error)
        }
    }
}

// MARK: - GeneratePasswordViewModelDelegate
extension CreateEditLoginViewModel: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        self.password = password
    }
}

// MARK: - AliasCreationDelegate
extension CreateEditLoginViewModel: AliasCreationDelegate {
    func aliasCreationInfo(_ info: AliasCreationInfo) {
        aliasCreationInfo = info
        username = info.aliasAddress
        isAlias = true
        createEditLoginViewModelDelegate?.createEditLoginViewModelDidReceiveAliasCreationInfo()
    }
}
