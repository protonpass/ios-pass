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
    private let passMonitorRepository: any PassMonitorRepositoryProtocol
    private let getPasswordStrength: any GetPasswordStrengthUseCase
    private let symmetricKeyProvider: any NonSendableSymmetricKeyProvider

    public init(passMonitorRepository: any PassMonitorRepositoryProtocol,
                symmetricKeyProvider: any NonSendableSymmetricKeyProvider,
                getPasswordStrength: any GetPasswordStrengthUseCase) {
        self.passMonitorRepository = passMonitorRepository
        self.getPasswordStrength = getPasswordStrength
        self.symmetricKeyProvider = symmetricKeyProvider
    }

    public func execute(for type: SecurityWeakness) -> AnyPublisher<SecurityIssuesContent, any Error> {
        passMonitorRepository.itemsWithSecurityIssues.tryMap { [weak self] items in
            guard let self else {
                return [:]
            }
            let key = try symmetricKeyProvider.getSymmetricKey()
            switch type {
            case .weakPasswords:
                return try filterWeakPasswords(items: items, type: type, key: key)
            case .reusedPasswords:
                return try filterReusedPasswords(items: items, type: type, key: key)
            case .missing2FA:
                return try filterMissing2fa(items: items, type: type, key: key)
            case .excludedItems:
                return try filterExcludedItems(items: items, type: type, key: key)
            default:
                return [:]
            }
        }.eraseToAnyPublisher()
    }
}

private extension GetAllSecurityAffectedLogins {
    func filterWeakPasswords(items: [SecurityAffectedItem],
                             type: SecurityWeakness,
                             key: SymmetricKey) throws -> SecurityIssuesContent {
        var weakPasswords: [SecuritySection: [ItemContent]] = [:]
        let section = SecuritySection.weakPasswords

        for item in items where item.weaknesses.contains(type) {
            let itemContent = try item.item.getItemContent(symmetricKey: key)

            if weakPasswords[section] != nil {
                weakPasswords[section]?.append(itemContent)
            } else {
                weakPasswords[section] = [itemContent]
            }
        }
        return weakPasswords
    }

    func filterReusedPasswords(items: [SecurityAffectedItem],
                               type: SecurityWeakness,
                               key: SymmetricKey) throws -> SecurityIssuesContent {
        var reusedPasswords: [SecuritySection: [ItemContent]] = [:]

        var intermediatePasswords: [String: Set<ItemContent>] = [:]

        for item in items where item.weaknesses.contains(type) {
            let itemContent = try item.item.getItemContent(symmetricKey: key)
            guard let password = itemContent.loginItem?.password else {
                continue
            }
            if intermediatePasswords[password] != nil {
                intermediatePasswords[password]?.insert(itemContent)
            } else {
                intermediatePasswords[password] = [itemContent]
            }
        }

        // Filter to keep only reused passwords
        intermediatePasswords.filter { $0.value.count > 1 }
            .forEach {
                let reusedKey = ReusedPasswordsKey(numberOfTimeReused: $0.value.count)
                reusedPasswords[SecuritySection.reusedPasswords(reusedKey)] = Array($0.value)
            }
        return reusedPasswords
    }

    func filterMissing2fa(items: [SecurityAffectedItem],
                          type: SecurityWeakness,
                          key: SymmetricKey) throws -> SecurityIssuesContent {
        let section = SecuritySection.missing2fa
        var missing2fas: [SecuritySection: [ItemContent]] = [section: []]

        for item in items where item.weaknesses.contains(type) {
            let itemContent = try item.item.getItemContent(symmetricKey: key)
            missing2fas[section]?.append(itemContent)
        }
        return missing2fas
    }

    func filterExcludedItems(items: [SecurityAffectedItem],
                             type: SecurityWeakness,
                             key: SymmetricKey) throws -> SecurityIssuesContent {
        let section = SecuritySection.excludedItems
        var excludedItems: [SecuritySection: [ItemContent]] = [section: []]

        for item in items where item.weaknesses.contains(type) {
            let itemContent = try item.item.getItemContent(symmetricKey: key)
            excludedItems[section]?.append(itemContent)
        }
        return excludedItems
    }
}
