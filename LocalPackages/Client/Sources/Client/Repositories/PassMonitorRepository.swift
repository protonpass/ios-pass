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
import CryptoKit
import Entities
import Foundation
import PassRustCore

public enum ItemFlag: Sendable, Hashable {
    case skipHealthCheck(Bool)
}

private struct InternalPassMonitorItem {
    let encrypted: SymmetricallyEncryptedItem
    let loginData: LogInItemData
}

// sourcery: AutoMockable
public protocol PassMonitorRepositoryProtocol: Sendable {
    var darkWebDataSectionUpdate: PassthroughSubject<DarkWebDataSectionUpdate, Never> { get }
    var userBreaches: CurrentValueSubject<UserBreaches?, Never> { get }
    var weaknessStats: CurrentValueSubject<WeaknessStats, Never> { get }
    var itemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never> { get }

    func refreshSecurityChecks() async throws
    func getItemsWithSamePassword(item: ItemContent) async throws -> [ItemContent]

    // MARK: - Breaches

    func refreshUserBreaches() async throws -> UserBreaches
    func getAllCustomEmailForUser() async throws -> [CustomEmail]
    func addEmailToBreachMonitoring(email: String) async throws -> CustomEmail
    func verifyCustomEmail(email: CustomEmail, code: String) async throws
    func removeEmailFromBreachMonitoring(email: CustomEmail) async throws
    func resendEmailVerification(emailId: String) async throws
    func getBreachesForAlias(sharedId: String, itemId: String) async throws -> EmailBreaches
    func getAllBreachesForEmail(email: CustomEmail) async throws -> EmailBreaches
    func getAllBreachesForProtonAddress(address: ProtonAddress) async throws -> EmailBreaches

    func markAliasAsResolved(sharedId: String, itemId: String) async throws
    func markProtonAddressAsResolved(address: ProtonAddress) async throws
    func markCustomEmailAsResolved(email: CustomEmail) async throws -> CustomEmail
    func toggleMonitoringFor(address: ProtonAddress, shouldMonitor: Bool) async throws
    func toggleMonitoringFor(email: CustomEmail, shouldMonitor: Bool) async throws -> CustomEmail
    func toggleMonitoringForAlias(sharedId: String, itemId: String, shouldMonitor: Bool) async throws
}

public actor PassMonitorRepository: PassMonitorRepositoryProtocol {
    private let itemRepository: any ItemRepositoryProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let passwordScorer: any PasswordScorerProtocol
    private let twofaDomainChecker: any TwofaDomainCheckerProtocol
    private let remoteDataSource: any RemoteBreachDataSourceProtocol

    public let darkWebDataSectionUpdate: PassthroughSubject<DarkWebDataSectionUpdate, Never> = .init()
    public let userBreaches: CurrentValueSubject<UserBreaches?, Never> = .init(nil)
    public let weaknessStats: CurrentValueSubject<WeaknessStats, Never> = .init(.default)
    public let itemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never> = .init([])

    private var cancellable = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?

    public init(itemRepository: any ItemRepositoryProtocol,
                remoteDataSource: any RemoteBreachDataSourceProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                passwordScorer: any PasswordScorerProtocol = PasswordScorer(),
                twofaDomainChecker: any TwofaDomainCheckerProtocol = TwofaDomainChecker()) {
        self.itemRepository = itemRepository
        self.symmetricKeyProvider = symmetricKeyProvider
        self.passwordScorer = passwordScorer
        self.twofaDomainChecker = twofaDomainChecker
        self.remoteDataSource = remoteDataSource

        Task { [weak self] in
            guard let self else {
                return
            }
            await setup()
        }
    }

    public func refreshSecurityChecks() async throws {
        var reusedPasswords = [String: Int]()
        let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
        let loginItems = try await itemRepository.getActiveLogInItems()
            .compactMap { encryptedItem -> InternalPassMonitorItem? in
                guard let item = try? encryptedItem.getItemContent(symmetricKey: symmetricKey),
                      let loginItem = item.loginItem else {
                    return nil
                }

                if !encryptedItem.item.skipHealthCheck, !loginItem.password.isEmpty {
                    reusedPasswords[loginItem.password, default: 0] += 1
                }
                return InternalPassMonitorItem(encrypted: encryptedItem, loginData: loginItem)
            }

        // Filter out unique passwords
        reusedPasswords = reusedPasswords.filter { $0.value > 1 }

        var numberOfWeakPassword = 0
        var numberOfMissing2fa = 0
        var numberOfExcludedItems = 0

        var securityAffectedItems = [SecurityAffectedItem]()

        for item in loginItems {
            var weaknesses = [SecurityWeakness]()

            if item.encrypted.item.skipHealthCheck {
                weaknesses.append(.excludedItems)
                numberOfExcludedItems += 1
            } else {
                if reusedPasswords[item.loginData.password] != nil {
                    weaknesses.append(.reusedPasswords)
                }

                if !item.loginData.password.isEmpty,
                   passwordScorer.checkScore(password: item.loginData.password) != .strong {
                    weaknesses.append(.weakPasswords)
                    numberOfWeakPassword += 1
                }

                if item.loginData.totpUri.isEmpty,
                   item.loginData.urls.contains(where: { twofaDomainChecker.twofaDomainEligible(domain: $0) }) {
                    weaknesses.append(.missing2FA)
                    numberOfMissing2fa += 1
                }
            }

            if !weaknesses.isEmpty {
                securityAffectedItems.append(SecurityAffectedItem(item: item.encrypted, weaknesses: weaknesses))
            }
        }
        weaknessStats.send(WeaknessStats(weakPasswords: numberOfWeakPassword,
                                         reusedPasswords: reusedPasswords.count,
                                         missing2FA: numberOfMissing2fa,
                                         excludedItems: numberOfExcludedItems))
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
                  !decriptedItem.item.skipHealthCheck,
                  let loginItem = decriptedItem.loginItem,
                  decriptedItem.ids != item.ids,
                  !loginItem.password.isEmpty, loginItem.password == login.password else {
                return nil
            }
            return decriptedItem
        }
    }
}

// MARK: - Breaches

public extension PassMonitorRepository {
    func refreshUserBreaches() async throws -> UserBreaches {
        let breaches = try await remoteDataSource.getAllBreachesForUser()
        userBreaches.send(breaches)
        return breaches
    }

    func getAllCustomEmailForUser() async throws -> [CustomEmail] {
        let emails = try await remoteDataSource.getAllCustomEmailForUser()
        return emails
    }

    func addEmailToBreachMonitoring(email: String) async throws -> CustomEmail {
        let email = try await remoteDataSource.addEmailToBreachMonitoring(email: email)
        return email
    }

    func verifyCustomEmail(email: CustomEmail, code: String) async throws {
        try await remoteDataSource.verifyCustomEmail(emailId: email.customEmailID, code: code)
    }

    func removeEmailFromBreachMonitoring(email: CustomEmail) async throws {
        try await remoteDataSource.removeEmailFromBreachMonitoring(emailId: email.customEmailID)
    }

    func resendEmailVerification(emailId: String) async throws {
        try await remoteDataSource.removeEmailFromBreachMonitoring(emailId: emailId)
    }

    func getBreachesForAlias(sharedId: String, itemId: String) async throws -> EmailBreaches {
        try Task.checkCancellation()
        return try await remoteDataSource.getBreachesForAlias(sharedId: sharedId, itemId: itemId)
    }

    func getAllBreachesForEmail(email: CustomEmail) async throws -> EmailBreaches {
        try Task.checkCancellation()
        return try await remoteDataSource.getAllBreachesForEmail(email: email)
    }

    func getAllBreachesForProtonAddress(address: ProtonAddress) async throws -> EmailBreaches {
        try Task.checkCancellation()
        return try await remoteDataSource.getAllBreachesForProtonAddress(address: address)
    }

    func markAliasAsResolved(sharedId: String, itemId: String) async throws {
        try Task.checkCancellation()
        return try await remoteDataSource.markAliasAsResolved(sharedId: sharedId, itemId: itemId)
    }

    func markProtonAddressAsResolved(address: ProtonAddress) async throws {
        try Task.checkCancellation()
        return try await remoteDataSource.markProtonAddressAsResolved(address: address)
    }

    func markCustomEmailAsResolved(email: CustomEmail) async throws -> CustomEmail {
        try Task.checkCancellation()
        return try await remoteDataSource.markCustomEmailAsResolved(email: email)
    }

    func toggleMonitoringFor(address: ProtonAddress, shouldMonitor: Bool) async throws {
        try Task.checkCancellation()
        return try await remoteDataSource.toggleMonitoringFor(address: address, shouldMonitor: shouldMonitor)
    }

    func toggleMonitoringFor(email: CustomEmail, shouldMonitor: Bool) async throws -> CustomEmail {
        try Task.checkCancellation()
        return try await remoteDataSource.toggleMonitoringFor(email: email, shouldMonitor: shouldMonitor)
    }

    func toggleMonitoringForAlias(sharedId: String, itemId: String, shouldMonitor: Bool) async throws {
        try Task.checkCancellation()
        return try await itemRepository.updateItemFlags(flags: [.skipHealthCheck(!shouldMonitor)],
                                                        shareId: sharedId,
                                                        itemId: itemId)
    }
}

private extension PassMonitorRepository {
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
            .dropFirst()
            .sink { [weak self] in
                guard let self else {
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
