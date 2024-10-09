//
// LoginDetailViewModel.swift
// Proton Pass - Created on 09/10/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Entities
import Factory
import Foundation
import UseCases

@MainActor
final class LoginDetailViewModel: ObservableObject {
    let type: ItemContentType
    var isAlias = false
    var email = ""
    var username = ""
    var password = ""
    var urls: [String] = []
    var totpUri = ""
    var passkeys = [Passkey]()
    var passwordStrength: PasswordStrength?

    private let getPasswordStrength = resolve(\SharedUseCasesContainer.getPasswordStrength)

    var coloredPassword: AttributedString {
        PasswordUtils.generateColoredPassword(password)
    }

    init(itemContent: ItemContent) {
        type = itemContent.type
        if case let .login(data) = itemContent.contentData {
            passkeys = data.passkeys
            email = data.email
            username = data.username
            password = data.password
            passwordStrength = getPasswordStrength(password: password)
            urls = data.urls
            totpUri = data.totpUri
//            totpManager.bind(uri: data.totpUri)
//            getAliasItem(email: data.email)

//            if !data.totpUri.isEmpty {
//                checkTotpState()
//            } else {
//                totpTokenState = .allowed
//            }
        } else {
            fatalError("Expecting login type")
        }
    }
}
