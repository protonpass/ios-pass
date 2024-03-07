//
//
// GetAllSecurityAffectedLogins.swift
// Proton Pass - Created on 07/03/2024.
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
import Combine
import CryptoKit
import Entities

public protocol GetAllSecurityAffectedLoginsUseCase: Sendable {
    func execute(for type: SecurityWeakness) -> AnyPublisher<[PasswordStrength: [ItemContent]], Never>
}

public extension GetAllSecurityAffectedLoginsUseCase {
    func callAsFunction(for type: SecurityWeakness) -> AnyPublisher<[PasswordStrength: [ItemContent]], Never> {
        execute(for: type)
    }
}

public final class GetAllSecurityAffectedLogins: GetAllSecurityAffectedLoginsUseCase {
    private let securityCenterRepository: any SecurityCenterRepositoryProtocol
    private let getPasswordStrength: any GetPasswordStrengthUseCase
    private let symmetricKeyProvider: any SymmetricKeyProvider

    public init(securityCenterRepository: any SecurityCenterRepositoryProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                getPasswordStrength: any GetPasswordStrengthUseCase) {
        self.securityCenterRepository = securityCenterRepository
        self.getPasswordStrength = getPasswordStrength
        self.symmetricKeyProvider = symmetricKeyProvider
    }

    public func execute(for type: SecurityWeakness) -> AnyPublisher<[PasswordStrength: [ItemContent]], Never> {
        securityCenterRepository.itemsWithSecurityIssues.map { [weak self] items in
            guard let self else {
                return [:]
            }
            switch type {
            case .weakPasswords:
                return filterWeakPasswords(items: items, type: type)
            default:
                return [:]
            }
        }.eraseToAnyPublisher()
    }
}

private extension GetAllSecurityAffectedLogins {
    func filterWeakPasswords(items: [SecurityAffectedItem],
                             type: SecurityWeakness) -> [PasswordStrength: [ItemContent]] {
        var results: [PasswordStrength: [ItemContent]] = [:]
        guard let key = try? symmetricKeyProvider.getSymmetricKey() else {
            return results
        }

        for item in items {
            guard item.weaknesses.contains(type),
                  let itemContent = try? item.item.getItemContent(symmetricKey: key),
                  let password = itemContent.loginItem?.password,
                  let strength = getPasswordStrength(password: password)
            else {
                continue
            }

            if results[strength] != nil {
                results[strength]?.append(itemContent)
            } else {
                results[strength] = [itemContent]
            }
        }
        return results
//
//        let filteredItems = items
//            .filter { $0.weaknesses.contains(type) }.compactMap { try? $0.item.getItemContent(symmetricKey: key)
//            }
//        return parseWeakPasswords(logins: filteredItems)
    }

//    func parseWeakPasswords(logins: [ItemContent]) -> [PasswordStrength: [ItemUiModel]] {
//        var results: [PasswordStrength: [ItemUiModel]] = [:]
//
//        for login in logins {
//            if let password = login.loginItem?.password,
//               let strength = getPasswordStrength(password: password),
//               strength != .strong {
//                if results[strength] != nil {
//                    results[strength]?.append(login.toItemUiModel)
//                } else {
//                    results[strength] = [login.toItemUiModel]
//                }
//            }
//        }
//
//        return results
//    }
}
