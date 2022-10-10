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

final class CreateEditLoginViewModel: BaseCreateEditItemViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published var title = ""
    @Published var username = ""
    @Published var password = ""
    @Published var isPasswordSecure = true // Password in clear text or not
    @Published var urls: [String] = [""]
    @Published var note = ""

    var onGeneratePassword: ((GeneratePasswordViewModelDelegate) -> Void)?

    private var hasNoUrls: Bool {
        urls.isEmpty || (urls.count == 1 && urls[0].isEmpty)
    }

    var isEmpty: Bool {
        title.isEmpty && username.isEmpty && password.isEmpty && hasNoUrls && note.isEmpty
    }

    override func bindValues() {
        if case let .edit(itemContent) = mode,
           case let .login(username, password, urls) = itemContent.contentData {
            self.title = itemContent.name
            self.username = username
            self.password = password
            self.urls = urls
            self.note = itemContent.note
        }
    }

    override func navigationBarTitle() -> String {
        switch mode {
        case .create:
            return "Create new login"
        case .edit:
            return "Edit login"
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

    @objc
    func generatePassword() {
        onGeneratePassword?(self)
    }

    func generateAlias() {
        let name = String.random(allowedCharacters: [.lowercase], length: 8)
        let host = String.random(allowedCharacters: [.lowercase], length: 5)
        let domain = String.random(allowedCharacters: [.lowercase], length: 5)
        username = "\(name)@\(host).\(domain)"
    }
}

// MARK: - GeneratePasswordViewModelDelegate
extension CreateEditLoginViewModel: GeneratePasswordViewModelDelegate {
    func generatePasswordViewModelDidConfirm(password: String) {
        self.password = password
    }
}
