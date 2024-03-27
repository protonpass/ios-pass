//
// PassMonitorRepository.swift
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
import Core
import CryptoKit
import Entities
import Foundation
import PassRustCore

public enum ItemFlag: Sendable, Hashable {
    case skipHealthCheck(Bool)
}

extension ItemFlag: Equatable {
    public static func == (lhs: ItemFlag, rhs: ItemFlag) -> Bool {
        switch (lhs, rhs) {
        case (.skipHealthCheck, .skipHealthCheck):
            true
        }
    }
}

// sourcery: AutoMockable
public protocol PassMonitorRepositoryProtocol: Sendable {
    var weaknessStats: CurrentValueSubject<WeaknessStats, Never> { get }
    var itemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never> { get }
//    var hasBreachedItems: CurrentValueSubject<Bool, Never> { get }

    func refreshSecurityChecks() async throws
    func getItemsWithSamePassword(item: ItemContent) async throws -> [ItemContent]
}

public actor PassMonitorRepository: PassMonitorRepositoryProtocol {
    private let itemRepository: any ItemRepositoryProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let passwordScorer: any PasswordScorerProtocol
    private let twofaDomainChecker: any TwofaDomainCheckerProtocol
    private let domainParser: (any DomainParsingProtocol)?

    public let weaknessStats: CurrentValueSubject<WeaknessStats, Never> = .init(.default)
    public let itemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never> = .init([])
//    public let hasBreachedItems: CurrentValueSubject<Bool, Never> = .init(false)

    private var cancellable = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?

    public init(itemRepository: any ItemRepositoryProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                passwordScorer: any PasswordScorerProtocol = PasswordScorer(),
                twofaDomainChecker: any TwofaDomainCheckerProtocol = TwofaDomainChecker(),
                domainParser: (any DomainParsingProtocol)? = try? DomainParser()) {
        self.itemRepository = itemRepository
        self.symmetricKeyProvider = symmetricKeyProvider
        self.passwordScorer = passwordScorer
        self.twofaDomainChecker = twofaDomainChecker
        self.domainParser = domainParser

        Task { [weak self] in
            guard let self else {
                return
            }
            await setup()
        }
    }

    public func refreshSecurityChecks() async throws {
        let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
        let encryptedItems = try await itemRepository.getActiveLogInItems()

        var numberOfWeakPassword = 0
        var numberOfReusedPassword = 0
        var numberOfMissing2fa = 0
        var numberOfExcludedItems = 0

        var securityAffectedItems = [SecurityAffectedItem]()

        // Filter out unique passwords and prepare the result
        let reusedPasswords = getPasswords(encryptedItems: encryptedItems, symmetricKey: symmetricKey)

        for encryptedItem in encryptedItems {
            guard let item = try? encryptedItem.getItemContent(symmetricKey: symmetricKey),
                  let loginItem = item.loginItem else {
                continue
            }

            var weaknesses = [SecurityWeakness]()

            if encryptedItem.item
                .isFlagActive(flagToCheck: ItemFlags.skipHealthCheck) {
                weaknesses.append(.excludedItems)
                numberOfExcludedItems += 1
            } else {
                if reusedPasswords[loginItem.password] != nil {
                    weaknesses.append(.reusedPasswords)
                    numberOfReusedPassword += 1
                }

                if !loginItem.password.isEmpty,
                   passwordScorer.checkScore(password: loginItem.password) != .strong {
                    weaknesses.append(.weakPasswords)
                    numberOfWeakPassword += 1
                }

                if loginItem.totpUri.isEmpty, contains2faDomains(urls: loginItem.urls) {
                    weaknesses.append(.missing2FA)
                    numberOfMissing2fa += 1
                }
            }

            // swiftlint:disable:next todo
            // TODO: check breached passwords /emails

            if !weaknesses.isEmpty {
                securityAffectedItems.append(SecurityAffectedItem(item: encryptedItem, weaknesses: weaknesses))
            }
        }
        weaknessStats.send(WeaknessStats(weakPasswords: numberOfWeakPassword,
                                         reusedPasswords: numberOfReusedPassword,
                                         missing2FA: numberOfMissing2fa,
                                         excludedItems: numberOfExcludedItems,
                                         exposedPasswords: 0))
        itemsWithSecurityIssues.send(securityAffectedItems)
    }

    public func getItemsWithSamePassword(item: ItemContent) async throws -> [ItemContent] {
        guard let login = item.loginItem else {
            return []
        }
        let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
        let encryptedItems = try await itemRepository.getActiveLogInItems()

        return encryptedItems.compactMap { encryptedItem in
            guard let decriptedItem = try? encryptedItem.getItemContent(symmetricKey: symmetricKey),
                  let loginItem = decriptedItem.loginItem,
                  decriptedItem.ids != item.ids,
                  !loginItem.password.isEmpty, loginItem.password == login.password else {
                return nil
            }
            return decriptedItem
        }
    }
}

private extension PassMonitorRepository {
    func getPasswords(encryptedItems: [SymmetricallyEncryptedItem], symmetricKey: SymmetricKey) -> [String: Int] {
        var passwordCounts = [String: Int]()

        // Count occurrences of each password
        for encryptedItem in encryptedItems {
            guard let item = try? encryptedItem.getItemContent(symmetricKey: symmetricKey),
                  let loginItem = item.loginItem,
                  !loginItem.password.isEmpty else {
                continue
            }
            passwordCounts[loginItem.password, default: 0] += 1
        }

        // Filter out unique passwords and prepare the result
        return passwordCounts.filter { $0.value > 1 }
    }

    func contains2faDomains(urls: [String]) -> Bool {
        urls
            .compactMap { domainParser?.parse(host: $0)?.domain }
            .contains { twofaDomainChecker.twofaDomainEligible(domain: $0) }
    }

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }
            try? await refreshSecurityChecks()
        }
    }

    func setup() {
        itemRepository.itemsWereUpdated
            .sink { [weak self] updated in
                guard let self, updated else {
                    return
                }
                Task { [weak self] in
                    guard let self else {
                        return
                    }
                    await refresh()
                }
            }
            .store(in: &cancellable)
        refresh()
    }
}
