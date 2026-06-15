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

public typealias SecurityIssuesContent = [SecuritySection: [ItemUiModel]]

public protocol GetAllSecurityAffectedLoginsUseCase: Sendable {
    func execute(for filter: MonitorWeaknessFilter) -> AnyPublisher<SecurityIssuesContent, any Error>
}

public extension GetAllSecurityAffectedLoginsUseCase {
    func callAsFunction(for filter: MonitorWeaknessFilter) -> AnyPublisher<SecurityIssuesContent, any Error> {
        execute(for: filter)
    }
}

public final class GetAllSecurityAffectedLogins: GetAllSecurityAffectedLoginsUseCase {
    private let passMonitorRepository: any PassMonitorRepositoryProtocol
    private let getPasswordStrength: any GetPasswordStrengthUseCase
    private let symmetricKeyProvider: any NonAsyncSymmetricKeyProvider

    public init(passMonitorRepository: any PassMonitorRepositoryProtocol,
                symmetricKeyProvider: any NonAsyncSymmetricKeyProvider,
                getPasswordStrength: any GetPasswordStrengthUseCase) {
        self.passMonitorRepository = passMonitorRepository
        self.getPasswordStrength = getPasswordStrength
        self.symmetricKeyProvider = symmetricKeyProvider
    }

    public func execute(for filter: MonitorWeaknessFilter) -> AnyPublisher<SecurityIssuesContent, any Error> {
        passMonitorRepository.itemsWithSecurityIssues.tryMap { [weak self] items in
            guard let self else {
                return [:]
            }
            let key = try symmetricKeyProvider.getSymmetricKey()
            switch filter {
            case .weakness(.weakPassword):
                return try filterActiveWeakness(.weakPassword, in: items, section: .weakPasswords, key: key)

            case .weakness(.reusedPassword):
                return try filterReusedPasswords(items: items, key: key)

            case .weakness(.missing2FA):
                return try filterActiveWeakness(.missing2FA, in: items, section: .missing2fa, key: key)

            case .weakness(.compromisedPassword):
                // Compromised-password detection is not surfaced yet (next MR).
                return [:]

            case .excludedItems:
                return try filterExcludedItems(items: items, key: key)
            }
        }.eraseToAnyPublisher()
    }
}

private extension GetAllSecurityAffectedLogins {
    /// Items whose ACTIVE weaknesses (detected and not suppressed) contain `kind`, grouped into `section`.
    func filterActiveWeakness(_ kind: WeaknessKind,
                              in items: [SecurityAffectedItem],
                              section: SecuritySection,
                              key: SymmetricKey) throws -> SecurityIssuesContent {
        var result: SecurityIssuesContent = [:]
        for item in items where item.activeWeaknesses.contains(kind) {
            let itemContent = try item.item.getItemContent(symmetricKey: key)
            result[section, default: []].append(itemContent.toItemUiModel)
        }
        return result
    }

    func filterReusedPasswords(items: [SecurityAffectedItem],
                               key: SymmetricKey) throws -> SecurityIssuesContent {
        var reusedPasswords: SecurityIssuesContent = [:]
        var intermediatePasswords: [String: Set<ItemUiModel>] = [:]

        for item in items where item.activeWeaknesses.contains(.reusedPassword) {
            let itemContent = try item.item.getItemContent(symmetricKey: key)
            guard let password = itemContent.loginItem?.password else {
                continue
            }
            intermediatePasswords[password, default: []].insert(itemContent.toItemUiModel)
        }

        // Filter to keep only reused passwords
        intermediatePasswords.filter { $0.value.count > 1 }
            .forEach {
                let reusedKey = ReusedPasswordsKey(numberOfTimeReused: $0.value.count)
                reusedPasswords[SecuritySection.reusedPasswords(reusedKey)] = Array($0.value)
            }
        return reusedPasswords
    }

    func filterExcludedItems(items: [SecurityAffectedItem],
                             key: SymmetricKey) throws -> SecurityIssuesContent {
        let section = SecuritySection.excludedItems
        var excludedItems: SecurityIssuesContent = [section: []]

        for item in items where item.isExcludedItem {
            let itemContent = try item.item.getItemContent(symmetricKey: key)
            excludedItems[section]?.append(itemContent.toItemUiModel)
        }
        return excludedItems
    }
}
