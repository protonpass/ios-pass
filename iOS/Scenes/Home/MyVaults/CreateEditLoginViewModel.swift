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
import Core
import SwiftUI

protocol CreateEditLoginViewModelDelegate: AnyObject {
    func createEditLoginViewModelWantsToGenerateAlias(_ delegate: AliasCreationDelegate,
                                                      title: String)
    func createEditLoginViewModelWantsToGeneratePassword(_ delegate: GeneratePasswordViewModelDelegate)
    func createEditLoginViewModelDidRemoveAlias()
}

final class CreateEditLoginViewModel: BaseCreateEditItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var isAlias = false // `Username` is an alias or a custom one
    @Published private(set) var isRemovingAlias = false
    @Published var title = ""
    @Published var username = ""
    @Published var password = ""
    @Published var isPasswordSecure = true // Password in clear text or not
    @Published var urls: [String] = [""]
    @Published var note = ""

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

    override func bindValues() {
        switch mode {
        case .edit(let itemContent):
            if case let .login(username, password, urls) = itemContent.contentData {
                self.title = itemContent.name
                self.username = username
                self.password = password
                if !urls.isEmpty { self.urls = urls }
                self.note = itemContent.note

                Task { @MainActor in
                    let aliasItem = try await itemRepository.getAliasItem(email: username)
                    self.isAlias = aliasItem != nil
                }
            }

        case let .create(_, type):
            if case let .login(title, url, _) = type, let title, let url {
                self.title = title
                self.urls = [url]
            }
        }
    }

    override func navigationBarTitle() -> String {
        switch mode {
        case .create:
            return "New login"
        case .edit:
            return "Edit"
        }
    }

    override func itemContentType() -> ItemContentType { .login }

    override func generateItemContent() -> ItemContentProtobuf {
        let sanitizedUrls = urls.compactMap { URLUtils.Sanitizer.sanitize($0) }
        let loginData = ItemContentData.login(username: username,
                                              password: password,
                                              urls: sanitizedUrls)
        return ItemContentProtobuf(name: title,
                                   note: note,
                                   data: loginData)
    }

    func generateAlias() {
        createEditLoginViewModelDelegate?
            .createEditLoginViewModelWantsToGenerateAlias(self, title: title)
    }

    func generatePassword() {
        createEditLoginViewModelDelegate?.createEditLoginViewModelWantsToGeneratePassword(self)
    }

    @MainActor
    func removeAlias() async {
        defer { isRemovingAlias = false }
        isRemovingAlias = true
        do {
            try await itemRepository.deleteAlias(email: username)
            username = ""
            isAlias = false
            createEditLoginViewModelDelegate?.createEditLoginViewModelDidRemoveAlias()
        } catch {
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
    func aliasCreationDidFinish(email: String) {
        username = email
        isAlias = true
    }
}
