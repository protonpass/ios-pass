//
//
// ValidateLogin.swift
// Proton Pass - Created on 28/09/2023.
// Copyright (c) 2023 Proton Technologies AG
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
//

@preconcurrency import PassRustCore

protocol ValidateLoginUseCase: Sendable {
    func execute(title: String,
                 username: String,
                 password: String,
                 totp: String?,
                 urls: [String]) throws
}

extension ValidateLoginUseCase {
    func callAsFunction(title: String,
                        username: String,
                        password: String,
                        totp: String?,
                        urls: [String]) throws {
        try execute(title: title,
                    username: username,
                    password: password,
                    totp: totp,
                    urls: urls)
    }
}

final class ValidateLogin: ValidateLoginUseCase {
    private let validator: any LoginValidatorProtocol

    init(validator: any LoginValidatorProtocol) {
        self.validator = validator
    }

    func execute(title: String,
                 username: String,
                 password: String,
                 totp: String?,
                 urls: [String]) throws {
        let loginItem = Login(title: title,
                              username: username,
                              password: password,
                              totp: totp,
                              urls: urls)
        try validator.validate(login: loginItem)
    }
}
