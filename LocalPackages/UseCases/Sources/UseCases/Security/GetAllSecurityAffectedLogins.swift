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

public typealias SecurityIssuesContent = [SecuritySection: [ItemUiModel]]

public protocol GetAllSecurityAffectedLoginsUseCase: Sendable {
    func callAsFunction(for filter: MonitorListSection) -> AnyPublisher<SecurityIssuesContent, Never>
}

public struct GetAllSecurityAffectedLogins: GetAllSecurityAffectedLoginsUseCase {
    private let passMonitorRepository: any PassMonitorRepositoryProtocol

    public init(passMonitorRepository: any PassMonitorRepositoryProtocol) {
        self.passMonitorRepository = passMonitorRepository
    }

    public func callAsFunction(for filter: MonitorListSection) -> AnyPublisher<SecurityIssuesContent, Never> {
        passMonitorRepository.itemsWithSecurityIssues
            .map { items in
                switch filter {
                case .weakness(.weakPassword):
                    filterActiveWeakness(.weakPassword, in: items, section: .weakPasswords)

                case .weakness(.reusedPassword):
                    filterReusedPasswords(items: items)

                case .weakness(.missing2FA):
                    filterActiveWeakness(.missing2FA, in: items, section: .missing2fa)

                case .weakness(.compromisedPassword):
                    filterActiveWeakness(.compromisedPassword,
                                         in: items,
                                         section: .compromisedPasswords)

                case .excludedItems:
                    filterExcludedItems(items: items)
                }
            }
            .eraseToAnyPublisher()
    }
}

private extension GetAllSecurityAffectedLogins {
    /// Items whose ACTIVE weaknesses (detected and not suppressed) contain `kind`, grouped into
    /// `section`. Reads the decrypt-once `display` projection, so it never re-decrypts.
    func filterActiveWeakness(_ kind: WeaknessKind,
                              in items: [SecurityAffectedItem],
                              section: SecuritySection) -> SecurityIssuesContent {
        var result: SecurityIssuesContent = [:]
        for item in items where item.activeWeaknesses.contains(kind) {
            result[section, default: []].append(item.display)
        }
        return result
    }

    func filterReusedPasswords(items: [SecurityAffectedItem]) -> SecurityIssuesContent {
        var reusedPasswords: SecurityIssuesContent = [:]
        var grouped: [Int: Set<ItemUiModel>] = [:]

        for item in items where item.activeWeaknesses.contains(.reusedPassword) {
            guard let group = item.reuseGroup else {
                continue
            }
            grouped[group, default: []].insert(item.display)
        }

        // Keep only passwords actually shared by more than one surfaced item.
        grouped.filter { $0.value.count > 1 }
            .forEach {
                let reusedKey = ReusedPasswordsKey(numberOfTimeReused: $0.value.count)
                reusedPasswords[SecuritySection.reusedPasswords(reusedKey)] = Array($0.value)
            }
        return reusedPasswords
    }

    func filterExcludedItems(items: [SecurityAffectedItem]) -> SecurityIssuesContent {
        let section = SecuritySection.excludedItems
        var excludedItems: SecurityIssuesContent = [section: []]
        for item in items where item.isExcludedItem {
            excludedItems[section]?.append(item.display)
        }
        return excludedItems
    }
}
