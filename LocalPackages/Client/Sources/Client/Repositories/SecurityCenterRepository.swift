//
// SecurityCenterRepository.swift
// Proton Pass - Created on 06/03/2024.
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

@preconcurrency import Combine
import CryptoKit
import Entities
import Foundation
import PassRustCore

// sourcery: AutoMockable
public protocol SecurityCenterRepositoryProtocol: Sendable {
    var weaknessStats: CurrentValueSubject<WeaknessStats, Never> { get }
    var itemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never> { get }
    var hasBreachedItems: CurrentValueSubject<Bool, Never> { get }

    func refreshSecurityChecks() async throws
}

public actor SecurityCenterRepository: SecurityCenterRepositoryProtocol {
    private let itemRepository: any ItemRepositoryProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let passwordScorer: any PasswordScorerProtocol

    public let weaknessStats: CurrentValueSubject<WeaknessStats, Never> = .init(.default)
    public let itemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never> = .init([])
    public let hasBreachedItems: CurrentValueSubject<Bool, Never> = .init(false)

    public init(itemRepository: any ItemRepositoryProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                passwordScorer: any PasswordScorerProtocol = PasswordScorer()) {
        self.itemRepository = itemRepository
        self.symmetricKeyProvider = symmetricKeyProvider
        self.passwordScorer = passwordScorer
        Task { [weak self] in
            guard let self else {
                return
            }
            try? await refreshSecurityChecks()
        }
    }

    public func refreshSecurityChecks() async throws {
        // swiftlint:disable:next todo
        // TODO: remove excluded items
        let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
        let encryptedItems = try await itemRepository.getActiveLogInItems()

        var numberOfWeakPassword = 0
        var numberOfReusedPassword = 0
        var securityAffectedItems = [SecurityAffectedItem]()

        // Filter out unique passwords and prepare the result
        let reusedPasswords = getPasswords(encryptedItems: encryptedItems, symmetricKey: symmetricKey)

        for encryptedItem in encryptedItems {
            guard let item = try? encryptedItem.getItemContent(symmetricKey: symmetricKey),
                  let loginItem = item.loginItem else {
                continue
            }
            var weaknesses = [SecurityWeakness]()

            if reusedPasswords[loginItem.password] != nil {
                weaknesses.append(.reusedPasswords)
                numberOfReusedPassword += 1
            }

            if passwordScorer.checkScore(password: loginItem.password) != .strong {
                weaknesses.append(.weakPasswords)
                numberOfWeakPassword += 1
            }
            // swiftlint:disable:next todo
            // TODO: check for missing 2FA and breached passwords /emails

            if !weaknesses.isEmpty {
                securityAffectedItems.append(SecurityAffectedItem(item: encryptedItem, weaknesses: weaknesses))
            }
        }
        weaknessStats.send(WeaknessStats(weakPasswords: numberOfWeakPassword,
                                         reusedPasswords: numberOfReusedPassword,
                                         missing2FA: 0,
                                         excludedItems: 0,
                                         exposedPasswords: 0))
        itemsWithSecurityIssues.send(securityAffectedItems)
    }
}

private extension SecurityCenterRepository {
    func getPasswords(encryptedItems: [SymmetricallyEncryptedItem], symmetricKey: SymmetricKey) -> [String: Int] {
        var passwordCounts = [String: Int]()

        // Count occurrences of each password
        for encryptedItem in encryptedItems {
            guard let item = try? encryptedItem.getItemContent(symmetricKey: symmetricKey),
                  let loginItem = item.loginItem else {
                continue
            }
            passwordCounts[loginItem.password, default: 0] += 1
        }

        // Filter out unique passwords and prepare the result
        return passwordCounts.filter { $0.value > 1 }
    }
}
