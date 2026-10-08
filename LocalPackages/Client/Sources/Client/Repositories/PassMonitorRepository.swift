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
@preconcurrency import CryptoKit
import Entities
import Foundation
import PassRustCore

private struct InternalPassMonitorItem {
    let encrypted: SymmetricallyEncryptedItem
    let content: Entities.ItemContent
    let loginData: LogInItemData
    let suppressedChecks: Set<WeaknessKind>
    let isOwned: Bool
}

private struct WeaknessComputation {
    let loginItems: [InternalPassMonitorItem]
    let reusedPasswords: [String: Int]
}

// sourcery: AutoMockable
public protocol PassMonitorRepositoryProtocol: Sendable {
    var darkWebDataSectionUpdate: PassthroughSubject<DarkWebDataSectionUpdate, Never> { get }
    var userBreaches: CurrentValueSubject<UserBreaches?, Never> { get }
    var weaknessStats: CurrentValueSubject<WeaknessStats?, Never> { get }
    var itemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never> { get }

    func refreshSecurityChecks() async throws
    func getItemsWithSamePassword(item: Entities.ItemContent) async throws -> [Entities.ItemContent]

    func reset() async

    func sendUserMonitorStats() async throws

    // MARK: - Breaches

    func refreshUserBreaches() async throws -> UserBreaches
    func getAllCustomEmailForUser() async throws -> [CustomEmail]
    func addEmailToBreachMonitoring(email: String) async throws -> CustomEmail
    func verifyCustomEmail(email: CustomEmail, code: String) async throws
    func removeEmailFromBreachMonitoring(email: CustomEmail) async throws
    func resendEmailVerification(email: CustomEmail) async throws
    func getBreachesForAlias(sharedId: String, itemId: String) async throws -> EmailBreaches
    func getAllBreachesForEmail(emailId: String) async throws -> EmailBreaches
    func getAllBreachesForProtonAddress(addressId: String) async throws -> EmailBreaches
    func markAliasAsResolved(sharedId: String, itemId: String) async throws
    func markProtonAddressAsResolved(address: ProtonAddress) async throws
    func markCustomEmailAsResolved(email: CustomEmail) async throws -> CustomEmail
    func toggleMonitoringFor(address: ProtonAddress, shouldMonitor: Bool) async throws
    func toggleMonitoringFor(email: CustomEmail, shouldMonitor: Bool) async throws -> CustomEmail
    func toggleMonitoringForAlias(sharedId: String, itemId: String, shouldMonitor: Bool) async throws
}

public actor PassMonitorRepository: PassMonitorRepositoryProtocol {
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let weaknessEvaluator: any ItemWeaknessEvaluatorProtocol
    private let remoteDataSource: any RemoteBreachDataSourceProtocol
    private let userManager: any UserManagerProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let compromisedPasswordChecker: any CompromisedPasswordCheckerProtocol
    private let isFeatureEnabled: @Sendable (FeatureFlagType) -> Bool

    public nonisolated let darkWebDataSectionUpdate: PassthroughSubject<DarkWebDataSectionUpdate, Never> = .init()
    public nonisolated let userBreaches: CurrentValueSubject<UserBreaches?, Never> = .init(nil)
    public nonisolated let weaknessStats: CurrentValueSubject<WeaknessStats?, Never> = .init(nil)
    public nonisolated let itemsWithSecurityIssues: CurrentValueSubject<[SecurityAffectedItem], Never> = .init([])

    private var cancellable = Set<AnyCancellable>()
    private var refreshTask: Task<Void, Never>?
    private var compromisedCheckTask: Task<Set<String>, any Error>?
    private var startedRefreshes = 0
    private var lastPublishedRefresh = 0

    private var lastPublishedBreachedItemIds: Set<String> {
        Set(itemsWithSecurityIssues.value
            .filter { $0.detected.contains(.compromisedPassword) }
            .map(\.id))
    }

    public init(itemRepository: any ItemRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                remoteDataSource: any RemoteBreachDataSourceProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                userManager: any UserManagerProtocol,
                accessRepository: any AccessRepositoryProtocol,
                compromisedPasswordChecker: any CompromisedPasswordCheckerProtocol,
                isFeatureEnabled: @escaping @Sendable (FeatureFlagType) -> Bool,
                weaknessEvaluator: any ItemWeaknessEvaluatorProtocol = ItemWeaknessEvaluator()) {
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.symmetricKeyProvider = symmetricKeyProvider
        self.weaknessEvaluator = weaknessEvaluator
        self.remoteDataSource = remoteDataSource
        self.userManager = userManager
        self.accessRepository = accessRepository
        self.compromisedPasswordChecker = compromisedPasswordChecker
        self.isFeatureEnabled = isFeatureEnabled

        Task { [weak self] in
            guard let self else {
                return
            }
            await setup()
        }
    }

    public func refreshSecurityChecks() async throws {
        startedRefreshes += 1
        let refreshNumber = startedRefreshes
        let userId = try await userManager.getActiveUserId()
        let compromisedCheckEnabled = await isCompromisedCheckEnabled(userId: userId)
        let loginItems = try await getLoginItems(userId: userId, compromisedCheckEnabled: compromisedCheckEnabled)
        let inputs = weaknessInputs(loginItems)
        // The actor is reentrant across the awaits: a newer refresh may already have published,
        // or reset() may have cleared the state, and publishing now would bring stale data back
        guard refreshNumber > lastPublishedRefresh else { return }
        lastPublishedRefresh = refreshNumber
        // The network check sends a request per password prefix, so the local results go out first with the
        // last known breaches
        let knownBreachedItemIds = compromisedCheckEnabled ? lastPublishedBreachedItemIds : []
        pushWeaknessState(buildStats(inputs, breachedItemIds: knownBreachedItemIds))

        guard compromisedCheckEnabled else { return }
        // A failed compromised check must not hide the local weak/reused/2FA results
        let breachedItemIds = await (try? compromisedItemIds(userId: userId, loginItems: loginItems)) ?? []
        guard refreshNumber == lastPublishedRefresh else { return }
        pushWeaknessState(buildStats(inputs, breachedItemIds: breachedItemIds))
    }

    public func getItemsWithSamePassword(item: Entities.ItemContent) async throws -> [Entities.ItemContent] {
        // Reads the last published refresh so the result matches the reused-password list exactly
        let affectedItems = itemsWithSecurityIssues.value
        guard let reuseGroup = affectedItems.first(where: { $0.item.ids == item.ids })?.reuseGroup else {
            return []
        }
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        return try affectedItems
            .filter { $0.reuseGroup == reuseGroup &&
                $0.item.ids != item.ids &&
                $0.activeWeaknesses.contains(.reusedPassword)
            }
            .map { try $0.item.getItemContent(symmetricKey: symmetricKey) }
    }

    public func reset() {
        // Consumes a refresh number so an in-flight refresh can't pass its second publish check
        startedRefreshes += 1
        lastPublishedRefresh = startedRefreshes
        userBreaches.send(nil)
        weaknessStats.send(nil)
        itemsWithSecurityIssues.send([])
        refreshTask?.cancel()
        refreshTask = nil
        compromisedCheckTask?.cancel()
        compromisedCheckTask = nil
    }
}

// MARK: - Breaches

public extension PassMonitorRepository {
    func refreshUserBreaches() async throws -> UserBreaches {
        let userId = try await userManager.getActiveUserId()
        let unsortedBreaches = try await remoteDataSource.getAllBreachesForUser(userId: userId)
        let breaches = UserBreaches(emailsCount: unsortedBreaches.emailsCount,
                                    domainsPeek: unsortedBreaches.domainsPeek,
                                    addresses: unsortedBreaches.addresses.sorted(),
                                    customEmails: unsortedBreaches.customEmails.sorted(),
                                    hasCustomDomains: unsortedBreaches.hasCustomDomains)
        userBreaches.send(breaches)
        return breaches
    }

    func getAllCustomEmailForUser() async throws -> [CustomEmail] {
        let userId = try await userManager.getActiveUserId()
        let emails = try await remoteDataSource.getAllCustomEmailForUser(userId: userId)
        return emails.sorted()
    }

    func addEmailToBreachMonitoring(email: String) async throws -> CustomEmail {
        let userId = try await userManager.getActiveUserId()
        return try await remoteDataSource.addEmailToBreachMonitoring(userId: userId, email: email)
    }

    func verifyCustomEmail(email: CustomEmail, code: String) async throws {
        let userId = try await userManager.getActiveUserId()
        try await remoteDataSource.verifyCustomEmail(userId: userId, emailId: email.customEmailID, code: code)
    }

    func removeEmailFromBreachMonitoring(email: CustomEmail) async throws {
        let userId = try await userManager.getActiveUserId()
        try await remoteDataSource.removeEmailFromBreachMonitoring(userId: userId, emailId: email.customEmailID)
    }

    func resendEmailVerification(email: CustomEmail) async throws {
        let userId = try await userManager.getActiveUserId()
        try await remoteDataSource.resendEmailVerification(userId: userId, emailId: email.customEmailID)
    }

    func getBreachesForAlias(sharedId: String, itemId: String) async throws -> EmailBreaches {
        try Task.checkCancellation()
        let userId = try await userManager.getActiveUserId()
        return try await remoteDataSource.getBreachesForAlias(userId: userId, sharedId: sharedId, itemId: itemId)
    }

    func getAllBreachesForEmail(emailId: String) async throws -> EmailBreaches {
        try Task.checkCancellation()
        let userId = try await userManager.getActiveUserId()
        return try await remoteDataSource.getAllBreachesForEmail(userId: userId, emailId: emailId)
    }

    func getAllBreachesForProtonAddress(addressId: String) async throws -> EmailBreaches {
        try Task.checkCancellation()
        let userId = try await userManager.getActiveUserId()
        return try await remoteDataSource.getAllBreachesForProtonAddress(userId: userId, addressId: addressId)
    }

    func markAliasAsResolved(sharedId: String, itemId: String) async throws {
        try Task.checkCancellation()
        let userId = try await userManager.getActiveUserId()
        try await remoteDataSource.markAliasAsResolved(userId: userId, sharedId: sharedId, itemId: itemId)
    }

    func markProtonAddressAsResolved(address: ProtonAddress) async throws {
        try Task.checkCancellation()
        let userId = try await userManager.getActiveUserId()
        try await remoteDataSource.markProtonAddressAsResolved(userId: userId, address: address)
    }

    func markCustomEmailAsResolved(email: CustomEmail) async throws -> CustomEmail {
        try Task.checkCancellation()
        let userId = try await userManager.getActiveUserId()
        return try await remoteDataSource.markCustomEmailAsResolved(userId: userId, email: email)
    }

    func toggleMonitoringFor(address: ProtonAddress, shouldMonitor: Bool) async throws {
        try Task.checkCancellation()
        let userId = try await userManager.getActiveUserId()
        try await remoteDataSource.toggleMonitoringFor(userId: userId,
                                                       address: address,
                                                       shouldMonitor: shouldMonitor)
    }

    func toggleMonitoringFor(email: CustomEmail, shouldMonitor: Bool) async throws -> CustomEmail {
        try Task.checkCancellation()
        let userId = try await userManager.getActiveUserId()
        return try await remoteDataSource.toggleMonitoringFor(userId: userId,
                                                              email: email,
                                                              shouldMonitor: shouldMonitor)
    }

    func toggleMonitoringForAlias(sharedId: String, itemId: String, shouldMonitor: Bool) async throws {
        try Task.checkCancellation()
        try await itemRepository.updateItemFlags(flags: [.skipHealthCheck(shouldMonitor)],
                                                 shareId: sharedId,
                                                 itemId: itemId)
    }

    func sendUserMonitorStats() async throws {
        try Task.checkCancellation()
        let userId = try await userManager.getActiveUserId()
        let compromisedCheckEnabled = await isCompromisedCheckEnabled(userId: userId)
        let visibleItems = try await getLoginItems(userId: userId,
                                                   compromisedCheckEnabled: compromisedCheckEnabled)
        // Checked here rather than read from the last published refresh, which may not have finished
        // yet. All visible items are passed because the checker prunes cached rows of non-candidates.
        var breachedItemIds: Set<String>?
        if compromisedCheckEnabled {
            breachedItemIds = try? await compromisedItemIds(userId: userId, loginItems: visibleItems)
        }
        let (stats, affectedItems) = buildStats(weaknessInputs(visibleItems.filter(\.isOwned)),
                                                breachedItemIds: breachedItemIds ?? [])
        let compromisedPasswords = breachedItemIds == nil ? nil : stats.count(for: .compromisedPassword)
        // The backend metric predates per-check exclusion and only counts items excluded from monitoring
        try await remoteDataSource.sendUserMonitorStats(userId: userId,
                                                        stats: stats,
                                                        excludedItems: affectedItems
                                                            .count(where: \.isFullyExcluded),
                                                        compromisedPasswords: compromisedPasswords)
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
        // A sync can update many items at once and each refresh decrypts every login, so
        // coalesce bursts into one refresh
        itemRepository.itemsWereUpdated
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.global())
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

    func getLoginItems(userId: String,
                       compromisedCheckEnabled: Bool) async throws -> [InternalPassMonitorItem] {
        let excludableChecks = excludableChecks(compromisedCheckEnabled: compromisedCheckEnabled)
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        let shares = try await shareRepository.getShares(userId: userId)
        let isOwnedByVisibleShareId = Dictionary(shares
            .filter(\.share.visible)
            .map { ($0.share.shareID, $0.share.owner) },
            uniquingKeysWith: { first, _ in first })

        return try await itemRepository.getActiveLogInItems(userId: userId)
            .compactMap { encryptedItem -> InternalPassMonitorItem? in
                guard let isOwned = isOwnedByVisibleShareId[encryptedItem.shareId],
                      let item = try? encryptedItem.getItemContent(symmetricKey: symmetricKey),
                      let loginItem = item.loginItem else {
                    return nil
                }
                return InternalPassMonitorItem(encrypted: encryptedItem,
                                               content: item,
                                               loginData: loginItem,
                                               suppressedChecks: encryptedItem.item.suppressedChecks
                                                   .intersection(excludableChecks),
                                               isOwned: isOwned)
            }
    }

    func weaknessInputs(_ loginItems: [InternalPassMonitorItem]) -> WeaknessComputation {
        var passwordCounts = [String: Int]()
        for item in loginItems where !item.encrypted.item.monitoringDisabled &&
            !item.suppressedChecks.contains(.reusedPassword) &&
            !item.loginData.password.isEmpty {
            passwordCounts[item.loginData.password, default: 0] += 1
        }
        let reuseGroups = Dictionary(uniqueKeysWithValues: passwordCounts
            .filter { $0.value > 1 }
            .keys
            .enumerated()
            .map { ($1, $0) })
        return WeaknessComputation(loginItems: loginItems, reusedPasswords: reuseGroups)
    }

    func buildStats(_ inputs: WeaknessComputation,
                    breachedItemIds: Set<String>) -> (WeaknessStats, [SecurityAffectedItem]) {
        let securityAffectedItems = inputs.loginItems.compactMap { item -> SecurityAffectedItem? in
            let reuseGroup = inputs.reusedPasswords[item.loginData.password]
            var detected = weaknessEvaluator.evaluate(item.loginData, isReused: reuseGroup != nil)
            if breachedItemIds.contains(item.content.id) {
                detected.insert(.compromisedPassword)
            }
            let affectedItem = SecurityAffectedItem(item: item.encrypted,
                                                    detected: detected,
                                                    display: item.content.toItemUiModel,
                                                    suppressedChecks: item.suppressedChecks,
                                                    reuseGroup: reuseGroup)
            return affectedItem.shouldBeIncluded ? affectedItem : nil
        }

        var weakPasswordCount = 0
        var missing2FACount = 0
        var excludedItemsCount = 0
        var compromisedPasswordCount = 0

        for item in securityAffectedItems {
            if item.activeWeaknesses.contains(.weakPassword) {
                weakPasswordCount += 1
            }

            if item.activeWeaknesses.contains(.missing2FA) {
                missing2FACount += 1
            }

            if item.activeWeaknesses.contains(.compromisedPassword) {
                compromisedPasswordCount += 1
            }

            if item.isExcludedItem {
                excludedItemsCount += 1
            }
        }

        let stats = WeaknessStats(counts: [
            .weakPassword: weakPasswordCount,
            .reusedPassword: inputs.reusedPasswords.count,
            .compromisedPassword: compromisedPasswordCount,
            .missing2FA: missing2FACount
        ],
        excludedItems: excludedItemsCount)
        return (stats, securityAffectedItems)
    }

    func pushWeaknessState(_ newState: (WeaknessStats, [SecurityAffectedItem])) {
        weaknessStats.send(newState.0)
        itemsWithSecurityIssues.send(newState.1)
    }

    func isCompromisedCheckEnabled(userId: String) async -> Bool {
        guard isFeatureEnabled(FeatureFlagType.passCompromisedPasswords),
              let plan = await (try? accessRepository.getPlan(userId: userId)) else {
            return false
        }
        return !plan.isFreeUser
    }

    func excludableChecks(compromisedCheckEnabled: Bool) -> Set<WeaknessKind> {
        guard isFeatureEnabled(FeatureFlagType.passMonitorPerCheckExclusion) else {
            return []
        }
        var checks = Set(WeaknessKind.allCases)
        if !compromisedCheckEnabled {
            checks.remove(.compromisedPassword)
        }
        return checks
    }

    /// Ids (itemId + shareId) of logins whose password is in the breach corpus. Fully excluded and
    /// check-suppressed logins are never sent.
    func compromisedItemIds(userId: String, loginItems: [InternalPassMonitorItem]) async throws -> Set<String> {
        let candidates = loginItems.compactMap { item -> CompromisedPasswordCandidate? in
            guard !item.encrypted.item.monitoringDisabled,
                  !item.suppressedChecks.contains(.compromisedPassword),
                  !item.loginData.password.isEmpty else {
                return nil
            }
            return CompromisedPasswordCandidate(shareId: item.encrypted.shareId,
                                                itemId: item.content.itemId,
                                                password: item.loginData.password)
        }
        guard !candidates.isEmpty else {
            return []
        }
        // Overlapping callers (launch refresh, monitor state, stats) would each run a full scan. Queued
        // behind the previous check, a caller finds the window restarted and fresh cache rows instead.
        let previousCheck = compromisedCheckTask
        let checker = compromisedPasswordChecker
        let check = Task {
            _ = await previousCheck?.result
            return try await checker.check(userId: userId, candidates: candidates)
        }
        compromisedCheckTask = check
        return try await withTaskCancellationHandler {
            try await check.value
        } onCancel: {
            check.cancel()
        }
    }
}

private extension [ProtonAddress] {
    func sorted() -> Self {
        sorted(by: { $0.breachCounter > $1.breachCounter })
    }
}

private extension [CustomEmail] {
    func sorted() -> Self {
        sorted(by: { $0.breachCounter > $1.breachCounter || ($0.verified && !$1.verified) })
    }
}
