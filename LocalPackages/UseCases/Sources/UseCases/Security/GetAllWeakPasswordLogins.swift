//
//
// GetAllWeakPasswordLogins.swift
// Proton Pass - Created on 01/03/2024.
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
//

import Client
import Entities

public protocol GetAllWeakPasswordLoginsUseCase: Sendable {
    func execute() async throws -> [PasswordStrength: [ItemContent]]
}

public extension GetAllWeakPasswordLoginsUseCase {
    func callAsFunction() async throws -> [PasswordStrength: [ItemContent]] {
        try await execute()
    }
}

public final class GetAllWeakPasswordLogins: GetAllWeakPasswordLoginsUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let getPasswordStrength: any GetPasswordStrengthUseCase

    public init(itemRepository: any ItemRepositoryProtocol,
                getPasswordStrength: any GetPasswordStrengthUseCase) {
        self.itemRepository = itemRepository
        self.getPasswordStrength = getPasswordStrength
    }

    public func execute() async throws -> [PasswordStrength: [ItemContent]] {
        let logins = try await itemRepository.getAllItemContents().filter { $0.contentData.type == .login }
        return parseWeakPasswords(logins: logins)
    }
}

private extension GetAllWeakPasswordLogins {
    func parseWeakPasswords(logins: [ItemContent]) -> [PasswordStrength: [ItemContent]] {
        var results: [PasswordStrength: [ItemContent]] = [:]

        for login in logins {
            if let password = login.loginItem?.password,
               let strength = getPasswordStrength(password: password),
               strength != .strong {
                if results[strength] != nil {
                    results[strength]?.append(login)
                } else {
                    results[strength] = [login]
                }
            }
        }

        return results
    }
}
