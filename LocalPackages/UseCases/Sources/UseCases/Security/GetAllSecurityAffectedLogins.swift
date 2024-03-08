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
import Entities

public typealias SecurityIssuesContent = [SecuritySection: [ItemContent]]

public protocol GetAllSecurityAffectedLoginsUseCase: Sendable {
    func execute(for type: SecurityWeakness) -> AnyPublisher<SecurityIssuesContent, any Error>
}

public extension GetAllSecurityAffectedLoginsUseCase {
    func callAsFunction(for type: SecurityWeakness) -> AnyPublisher<SecurityIssuesContent, any Error> {
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

    public func execute(for type: SecurityWeakness) -> AnyPublisher<SecurityIssuesContent, any Error> {
        securityCenterRepository.itemsWithSecurityIssues.tryMap { [weak self] items in
            guard let self else {
                return [:]
            }
            switch type {
            case .weakPasswords:
                return try filterWeakPasswords(items: items, type: type)
            default:
                return [:]
            }
        }.eraseToAnyPublisher()
    }
}

private extension GetAllSecurityAffectedLogins {
    func filterWeakPasswords(items: [SecurityAffectedItem],
                             type: SecurityWeakness) throws -> SecurityIssuesContent {
        var results: [SecuritySection: [ItemContent]] = [:]
        let key = try symmetricKeyProvider.getSymmetricKey()

        for item in items {
            guard item.weaknesses.contains(type) else {
                continue
            }
            let itemContent = try item.item.getItemContent(symmetricKey: key)
            guard let password = itemContent.loginItem?.password,
                  let strength = getPasswordStrength(password: password) else {
                continue
            }
            let section = SecuritySection.weakPasswords(strength)
            if results[section] != nil {
                results[section]?.append(itemContent)
            } else {
                results[section] = [itemContent]
            }
        }
        return results
    }
}