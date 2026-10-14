//  
// PassMonitorRepositoryTests.swift
// Proton Pass - Created on 28/03/2024.
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

@testable import Client
import ClientMocks
import Combine
import Core
import CoreMocks
import CryptoKit
import Entities
import EntitiesMocks
import Foundation
import Testing

/// Test-local description of the fixture item to build (decoupled from the production weakness types).
enum FixtureWeakness {
    case reusedPasswords
    case weakPasswords
    case missing2FA
    case fullyExcluded
}

private actor GatedCompromisedPasswordChecker: CompromisedPasswordCheckerProtocol {
    private(set) var invocationCount = 0
    private(set) var maxConcurrentChecks = 0
    private var runningChecks = 0
    private var isOpen = false
    private var waiters = [CheckedContinuation<Void, Never>]()

    func check(userId: String, candidates: [CompromisedPasswordCandidate]) async -> Set<String> {
        invocationCount += 1
        runningChecks += 1
        maxConcurrentChecks = max(maxConcurrentChecks, runningChecks)
        defer { runningChecks -= 1 }
        if !isOpen {
            await withCheckedContinuation { waiters.append($0) }
        }
        // Like the real checker, a cancelled scan only reports its cache hits, and this one has none
        return Task.isCancelled ? [] : Set(candidates.map(\.id))
    }

    func open() {
        isOpen = true
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }

    func close() {
        isOpen = false
    }
}

@Suite(.tags(.repository))
struct PassMonitorRepositoryTests {
    let symmetricKeyProviderMockFactory: SymmetricKeyProviderMockFactory
    let itemRepository: ItemRepositoryProtocolMock
    let shareRepository: ShareRepositoryProtocolMock
    let sut: PassMonitorRepositoryProtocol
    let userManager: UserManagerProtocolMock

    init() {
        userManager = .init()
        userManager.stubbedGetActiveUserDataResult = .preview
        symmetricKeyProviderMockFactory = .init()
        symmetricKeyProviderMockFactory.setUp()
        itemRepository = ItemRepositoryProtocolMock()
        itemRepository.stubbedGetActiveLogInItemsResult = []
        itemRepository.stubbedItemsWereUpdated = .init(())
        shareRepository = ShareRepositoryProtocolMock()
        shareRepository.stubbedGetSharesResult = []
        // Free plan => compromised-password detection (a paid feature) is skipped, so these tests
        // exercise only the local weakness checks.
        let accessRepository = Self.makeAccessRepository(planType: "free")
        sut = PassMonitorRepository(itemRepository: itemRepository,
                                    shareRepository: shareRepository,
                                    remoteDataSource: RemoteBreachDataSourceProtocolMock(),
                                    symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                                    userManager: userManager,
                                    accessRepository: accessRepository,
                                    compromisedPasswordChecker: CompromisedPasswordCheckerProtocolMock(),
                                    isFeatureEnabled: { _ in true })
    }

    static func makeAccessRepository(planType: String) -> AccessRepositoryProtocolMock {
        let accessRepository = AccessRepositoryProtocolMock()
        accessRepository.stubbedGetAccessResult = UserAccess(userId: "test",
                                                             access: Access(plan: .init(type: planType,
                                                                                        internalName: planType,
                                                                                        displayName: "Free",
                                                                                        hideUpgrade: false,
                                                                                        manageAlias: false,
                                                                                        trialEnd: nil,
                                                                                        vaultLimit: 1,
                                                                                        aliasLimit: 10,
                                                                                        totpLimit: 3,
                                                                                        storageAllowed: false,
                                                                                        storageUsed: 0,
                                                                                        storageQuota: 0,
                                                                                        folderAllowed: false,
                                                                                        folderMaxCount: 0,
                                                                                        folderMaxChildren: 0,
                                                                                        folderMaxDepth: 0),
                                                                            monitor: .init(protonAddress: true,
                                                                                           aliases: false),
                                                                            pendingInvites: 0,
                                                                            waitingNewUserInvites: 0,
                                                                            minVersionUpgrade: nil,
                                                                            userData: UserAliasSyncData.default))
        return accessRepository
    }

    func createEncryptedLoginItems(weakness: [FixtureWeakness], addStrong: Bool = true) -> [SymmetricallyEncryptedItem] {
        let shareID = UUID().uuidString
        var items = [SymmetricallyEncryptedItem]()
        let key = symmetricKeyProviderMockFactory.key
        shareRepository.stubbedGetSharesResult = [SymmetricallyEncryptedShare(encryptedContent: nil, share: .random(shareId: shareID))]

        for weakness in weakness {
            switch weakness {
            case .reusedPasswords:
                let loginData = LogInItemData.mock(password: "Ageless6-Evidence0-Detonator1-Cider4-Synthesis6sdfasdsad")
                let reused1Login = ItemContentProtobufFactory.createItemContentProtobuf(name: "Example Login",
                                                                                        note: "This is a note.",
                                                                                        itemUuid: UUID().uuidString,
                                                                                        data: .login(loginData),
                                                                                        customFields: [])
                items.append(SymmetricallyEncryptedItem.random(shareId: shareID,
                                                               item: Item.monitoredMock,
                                                               encryptedContent: try! reused1Login.encrypt(symmetricKey: key)))

            case .weakPasswords:
                let loginData = LogInItemData.mock(username: "test", password: "aaaaa")
                let weakpassLogin = ItemContentProtobufFactory.createItemContentProtobuf(name: "Example Login",
                                                                                         note: "This is a note.",
                                                                                         itemUuid: UUID().uuidString,
                                                                                         data: .login(loginData),
                                                                                         customFields: [])
                items.append(SymmetricallyEncryptedItem.random(shareId: shareID,
                    item: Item.monitoredMock,
                                                               encryptedContent: try! weakpassLogin.encrypt(symmetricKey: key)))
            case .fullyExcluded:
                let loginData = LogInItemData.mock(totpUri: "", urls: ["google.com"])
                let nonMonitorLogin = ItemContentProtobufFactory.createItemContentProtobuf(name: "Example Login",
                                                                                           note: "This is a note.",
                                                                                           itemUuid: UUID().uuidString,
                                                                                           data: .login(loginData),
                                                                                           customFields: [])
                items.append(SymmetricallyEncryptedItem.random(shareId: shareID,
                    item: Item.notMonitoredMock,
                                                               encryptedContent: try! nonMonitorLogin.encrypt(symmetricKey: key)))
            case .missing2FA:
                let loginData = LogInItemData.mock(username: "test", password: "Ageless6-Evidence0-Detonator1-Cider4-Synthesis6sdf", totpUri: "", urls: ["google.com"])
                let no2FALogin = ItemContentProtobufFactory.createItemContentProtobuf(name: "Example Login",
                                                                                      note: "This is a note.",
                                                                                      itemUuid: UUID().uuidString,
                                                                                      data: .login(loginData),
                                                                                      customFields: [])
                items.append(SymmetricallyEncryptedItem.random(shareId: shareID,
                    item: Item.monitoredMock,
                                                               encryptedContent: try! no2FALogin.encrypt(symmetricKey: key)))
            }
        }
        
        if addStrong {
            let loginData = LogInItemData.mock(username: "Strong item", password: "Ageless6-Evidence0-Detonator1-Cider4-Synthesis4")
            let noWeaknessLogin = ItemContentProtobufFactory.createItemContentProtobuf(name: "Example Login",
                                                                                       note: "This is a note.",
                                                                                       itemUuid: UUID().uuidString,
                                                                                       data: .login(loginData),
                                                                                       customFields: [])
            items.append(SymmetricallyEncryptedItem.random(shareId: shareID,
                item: Item.monitoredMock,
                                                           encryptedContent: try! noWeaknessLogin.encrypt(symmetricKey: key)))
        }
        
        return items
    }

    @Test func `PassMonitorRepository operations`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [
            .reusedPasswords,
            .reusedPasswords,
            .weakPasswords,
            .missing2FA,
            .fullyExcluded
        ])

        try await sut.refreshSecurityChecks()

        let state = try #require(sut.weaknessStats.value)
        // Per-check exclusion is on, so the fully-excluded flag is ignored: that item's weak password and
        // missing 2FA count
        #expect(state.count(for: .reusedPassword) == 1)
        #expect(state.count(for: .weakPassword) == 2)
        #expect(state.excludedItems == 0)
        #expect(state.count(for: .missing2FA) == 2)


        let itemsWithSecurityIssues = sut.itemsWithSecurityIssues.value
        #expect(itemsWithSecurityIssues.count == 5)

        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [])
        try await sut.refreshSecurityChecks()
        
        let itemsWithSecurityNoIssues = sut.itemsWithSecurityIssues.value
        #expect(itemsWithSecurityNoIssues.count == 0)

        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [
            .reusedPasswords,
            .reusedPasswords,
            .reusedPasswords,
            .reusedPasswords
        ])
        try await sut.refreshSecurityChecks()
        
        let itemsWithSecurityOnlyReused = sut.itemsWithSecurityIssues.value
        #expect(itemsWithSecurityOnlyReused.count == 4)
        let state2 = try #require(sut.weaknessStats.value)
        #expect(state2.count(for: .reusedPassword) == 1)
        #expect(state2.count(for: .weakPassword) == 0)
        #expect(state2.excludedItems == 0)
        #expect(state2.count(for: .missing2FA) == 0)

        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [
            .weakPasswords,
            .weakPasswords,
            .weakPasswords
        ])
        try await sut.refreshSecurityChecks()
        
        let itemsWithSecurityReusedWeak = sut.itemsWithSecurityIssues.value
        #expect(itemsWithSecurityReusedWeak.count == 3)
        let state3 = try #require(sut.weaknessStats.value)
        #expect(state3.count(for: .reusedPassword) == 1)
        #expect(state3.count(for: .weakPassword) == 3)
        #expect(state3.excludedItems == 0)
        #expect(state3.count(for: .missing2FA) == 0)
    }
    
    @Test func `Items sharing a password share a reuse group, unique passwords have none`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [
            .reusedPasswords,
            .reusedPasswords,
            .weakPasswords,
            .weakPasswords,
            .missing2FA
        ])

        try await sut.refreshSecurityChecks()

        let groups = sut.itemsWithSecurityIssues.value.map(\.reuseGroup)
        try #require(groups.count == 5)
        let firstGroup = try #require(groups[0])
        let secondGroup = try #require(groups[2])
        #expect(groups[1] == firstGroup)
        #expect(groups[3] == secondGroup)
        #expect(firstGroup != secondGroup)
        #expect(groups[4] == nil)
    }

    /// IDTEAM-5965: the weakness stays detected, so it reappears if monitoring is re-enabled.
    @Test func `Without per-check exclusion a fully-excluded item is excluded only`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = makeFullyExcludedWeakItems()
        let checker = CompromisedPasswordCheckerProtocolMock()
        checker.stubbedCheckResult = []
        let sut = makePaidSut(checker: checker, isFeatureEnabled: { $0 != .passMonitorPerCheckExclusion })

        try await sut.refreshSecurityChecks()

        let stats = try #require(sut.weaknessStats.value)
        #expect(stats.excludedItems == 1)
        #expect(stats.count(for: .weakPassword) == 0)

        let affected = sut.itemsWithSecurityIssues.value
        #expect(affected.count == 1)
        let item = try #require(affected.first)
        #expect(item.isFullyExcluded)
        #expect(item.isExcludedItem)
        #expect(item.detected.contains(.weakPassword))   // still detected...
        #expect(item.activeWeaknesses.isEmpty)            // ...but not surfaced as active
        #expect(!checker.invokedCheckfunction)
    }

    @Test func `With per-check exclusion the fully-excluded flag is ignored`() async throws {
        let items = makeFullyExcludedWeakItems()
        itemRepository.stubbedGetActiveLogInItemsResult = items
        let checker = CompromisedPasswordCheckerProtocolMock()
        let legacyExcluded = try #require(items.first)
        checker.stubbedCheckResult = [legacyExcluded.itemId + legacyExcluded.shareId]
        let sut = makePaidSut(checker: checker)

        try await sut.refreshSecurityChecks()
        try await waitUntil { sut.weaknessStats.value?.count(for: .compromisedPassword) == 1 }

        let stats = try #require(sut.weaknessStats.value)
        #expect(stats.excludedItems == 0)
        #expect(stats.count(for: .weakPassword) == 1)
        let item = try #require(sut.itemsWithSecurityIssues.value.first)
        #expect(!item.isFullyExcluded)
        #expect(!item.isExcludedItem)
        #expect(item.activeWeaknesses == [.weakPassword, .compromisedPassword])
    }

    @Test func `With per-check exclusion a fully-excluded login still counts as reused`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = makeReusePairOneSuppressed(firstItemFlags: 1)

        try await sut.refreshSecurityChecks()

        #expect(sut.weaknessStats.value?.count(for: .reusedPassword) == 1)
        #expect(sut.itemsWithSecurityIssues.value.count(where: { $0.activeWeaknesses.contains(.reusedPassword) })
            == 2)
    }

    /// Distinct weak passwords, so none of them is also reused
    func makeWeakLogins(flags: [Int]) -> [SymmetricallyEncryptedItem] {
        let shareID = UUID().uuidString
        let key = symmetricKeyProviderMockFactory.key
        shareRepository.stubbedGetSharesResult =
            [SymmetricallyEncryptedShare(encryptedContent: nil, share: .random(shareId: shareID))]
        return flags.enumerated().map { index, flags in
            let loginData = LogInItemData.mock(username: "test", password: "weak\(index)")
            let content = ItemContentProtobufFactory.createItemContentProtobuf(name: "Login",
                                                                               note: "n",
                                                                               itemUuid: UUID().uuidString,
                                                                               data: .login(loginData),
                                                                               customFields: [])
            return SymmetricallyEncryptedItem.random(shareId: shareID,
                                                     item: .random(flags: flags),
                                                     encryptedContent: try! content.encrypt(symmetricKey: key))
        }
    }

    func makeFullyExcludedWeakItems() -> [SymmetricallyEncryptedItem] {
        let shareID = UUID().uuidString
        let key = symmetricKeyProviderMockFactory.key
        shareRepository.stubbedGetSharesResult =
            [SymmetricallyEncryptedShare(encryptedContent: nil, share: .random(shareId: shareID))]
        let loginData = LogInItemData.mock(username: "test", password: "aaaaa")
        let login = ItemContentProtobufFactory.createItemContentProtobuf(name: "Excluded weak login",
                                                                          note: "This is a note.",
                                                                          itemUuid: UUID().uuidString,
                                                                          data: .login(loginData),
                                                                          customFields: [])
        return [SymmetricallyEncryptedItem.random(shareId: shareID,
                                                  item: Item.notMonitoredMock,
                                                  encryptedContent: try! login.encrypt(symmetricKey: key))]
    }

    @Test func `A reuse-suppressed login still detects its shared password but its partner is not flagged`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = makeReusePairOneSuppressed()

        try await sut.refreshSecurityChecks()
        let affected = sut.itemsWithSecurityIssues.value

        let suppressed = try #require(affected.first { $0.suppressedChecks.contains(.reusedPassword) })
        #expect(affected.count == 1)
        #expect(suppressed.suppressedWeaknesses == [.reusedPassword])
        #expect(!suppressed.activeWeaknesses.contains(.reusedPassword))
        #expect(suppressed.isExcludedItem)
        #expect(sut.weaknessStats.value?.count(for: .reusedPassword) == 0)
    }

    @Test func `A reuse-suppressed login no longer detects reuse once its password is unique`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = Array(makeReusePairOneSuppressed().prefix(1))

        try await sut.refreshSecurityChecks()

        let suppressed = try #require(sut.itemsWithSecurityIssues.value.first)
        #expect(suppressed.suppressedWeaknesses.isEmpty)
        #expect(suppressed.isExcludedItem)
    }

    @Test func `A compromise-suppressed login is still checked without counting as compromised`() async throws {
        // 64 = skipCompromisedPasswordCheck (1 << 6)
        let login = try #require(makeWeakLogins(flags: [64]).first)
        itemRepository.stubbedGetActiveLogInItemsResult = [login]
        let checker = CompromisedPasswordCheckerProtocolMock()
        checker.stubbedCheckResult = [login.itemId + login.shareId]
        let sut = makePaidSut(checker: checker)

        try await sut.refreshSecurityChecks()
        try await waitUntil {
            sut.itemsWithSecurityIssues.value.first?.detected.contains(.compromisedPassword) == true
        }

        #expect(checker.invokedCheckParameters?.candidates.map(\.id) == [login.itemId + login.shareId])
        let item = try #require(sut.itemsWithSecurityIssues.value.first)
        #expect(item.suppressedWeaknesses == [.compromisedPassword])
        #expect(item.activeWeaknesses == [.weakPassword])
        let stats = try #require(sut.weaknessStats.value)
        #expect(stats.count(for: .compromisedPassword) == 0)
        #expect(stats.excludedItems == 1)
    }

    @Test func `A compromise-suppressed login no longer detects the breach once its password is safe`() async throws {
        let login = try #require(makeWeakLogins(flags: [64]).first)
        itemRepository.stubbedGetActiveLogInItemsResult = [login]
        let checker = CompromisedPasswordCheckerProtocolMock()
        checker.stubbedCheckResult = []
        let sut = makePaidSut(checker: checker)

        try await sut.refreshSecurityChecks()

        let item = try #require(sut.itemsWithSecurityIssues.value.first)
        #expect(item.suppressedWeaknesses.isEmpty)
        #expect(item.isExcludedItem)
    }

    func makeReusePairOneSuppressed(firstItemFlags: Int = 128) -> [SymmetricallyEncryptedItem] {
        let shareID = UUID().uuidString
        let key = symmetricKeyProviderMockFactory.key
        shareRepository.stubbedGetSharesResult =
            [SymmetricallyEncryptedShare(encryptedContent: nil, share: .random(shareId: shareID))]
        let shared = "Ageless6-Evidence0-Detonator1-Cider4-Synthesis6sdfasdsad"

        func make(flags: Int) -> SymmetricallyEncryptedItem {
            let loginData = LogInItemData.mock(username: "test", password: shared)
            let content = ItemContentProtobufFactory.createItemContentProtobuf(name: "Login",
                                                                               note: "n",
                                                                               itemUuid: UUID().uuidString,
                                                                               data: .login(loginData),
                                                                               customFields: [])
            return SymmetricallyEncryptedItem.random(shareId: shareID,
                                                     item: .random(flags: flags),
                                                     encryptedContent: try! content.encrypt(symmetricKey: key))
        }
        // 128 = skipReusedPasswordCheck (1 << 7); 0 = fully monitored.
        return [make(flags: firstItemFlags), make(flags: 0)]
    }

    @Test func `Reuse suppression is ignored when per-check exclusion is disabled`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = makeReusePairOneSuppressed()
        let checker = CompromisedPasswordCheckerProtocolMock()
        checker.stubbedCheckResult = []
        let sut = makePaidSut(checker: checker,
                              isFeatureEnabled: { $0 != .passMonitorPerCheckExclusion })

        try await sut.refreshSecurityChecks()

        let affected = sut.itemsWithSecurityIssues.value
        #expect(affected.count == 2)
        #expect(affected.allSatisfy { $0.activeWeaknesses.contains(.reusedPassword) })
        #expect(affected.allSatisfy { !$0.isExcludedItem })
        let stats = try #require(sut.weaknessStats.value)
        #expect(stats.count(for: .reusedPassword) == 1)
        #expect(stats.excludedItems == 0)
    }

    @Test func `Compromised suppression is ignored when the compromised check is disabled`() async throws {
        let shareID = UUID().uuidString
        let key = symmetricKeyProviderMockFactory.key
        shareRepository.stubbedGetSharesResult =
            [SymmetricallyEncryptedShare(encryptedContent: nil, share: .random(shareId: shareID))]
        let loginData = LogInItemData.mock(username: "test",
                                           password: "Ageless6-Evidence0-Detonator1-Cider4-Synthesis6sdfasdsad")
        let content = ItemContentProtobufFactory.createItemContentProtobuf(name: "Login",
                                                                           note: "n",
                                                                           itemUuid: UUID().uuidString,
                                                                           data: .login(loginData),
                                                                           customFields: [])
        // 64 = skipCompromisedPasswordCheck (1 << 6)
        itemRepository.stubbedGetActiveLogInItemsResult = [
            SymmetricallyEncryptedItem.random(shareId: shareID,
                                              item: .random(flags: 64),
                                              encryptedContent: try content.encrypt(symmetricKey: key))
        ]
        let sut = makePaidSut(checker: CompromisedPasswordCheckerProtocolMock(),
                              isFeatureEnabled: { $0 != .passCompromisedPasswords })

        try await sut.refreshSecurityChecks()

        #expect(sut.itemsWithSecurityIssues.value.isEmpty)
        #expect(try #require(sut.weaknessStats.value).excludedItems == 0)
    }

    @Test func `Compromised check is skipped for paid users when its flag is disabled`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [.weakPasswords])
        let checker = CompromisedPasswordCheckerProtocolMock()
        let remote = RemoteBreachDataSourceProtocolMock()
        let sut = makePaidSut(checker: checker,
                              remoteDataSource: remote,
                              isFeatureEnabled: { $0 != .passCompromisedPasswords })

        try await sut.refreshSecurityChecks()
        try await sut.sendUserMonitorStats()

        #expect(!checker.invokedCheckfunction)
        let sent = try #require(remote.invokedSendUserMonitorStatsParameters)
        #expect(sent.compromisedPasswords == nil)
        #expect(sent.stats.count(for: .weakPassword) == 1)
    }

    func makePaidSut(checker: any CompromisedPasswordCheckerProtocol,
                     remoteDataSource: RemoteBreachDataSourceProtocolMock = .init(),
                     isFeatureEnabled: @escaping @Sendable (FeatureFlagType) -> Bool = { _ in true },
                     weaknessEvaluator: any ItemWeaknessEvaluatorProtocol = ItemWeaknessEvaluator())
        -> PassMonitorRepository {
        PassMonitorRepository(itemRepository: itemRepository,
                              shareRepository: shareRepository,
                              remoteDataSource: remoteDataSource,
                              symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                              userManager: userManager,
                              accessRepository: Self.makeAccessRepository(planType: "plus"),
                              compromisedPasswordChecker: checker,
                              isFeatureEnabled: isFeatureEnabled,
                              weaknessEvaluator: weaknessEvaluator)
    }

    @Test func `A refresh evaluates each login once even with the compromised check`() async throws {
        let items = createEncryptedLoginItems(weakness: [.weakPasswords])
        itemRepository.stubbedGetActiveLogInItemsResult = items
        let checker = CompromisedPasswordCheckerProtocolMock()
        let breached = try #require(items.first)
        checker.stubbedCheckResult = [breached.itemId + breached.shareId]
        let evaluator = ItemWeaknessEvaluatorProtocolMock()
        evaluator.stubbedEvaluateResult = []
        let sut = makePaidSut(checker: checker, weaknessEvaluator: evaluator)
        try await sut.refreshSecurityChecks()
        try await waitUntil { sut.weaknessStats.value?.count(for: .compromisedPassword) == 1 }
        evaluator.invokedEvaluateCount = 0

        try await sut.refreshSecurityChecks()

        #expect(evaluator.invokedEvaluateCount == items.count)
    }

    @Test func `A failing compromised check still publishes the local weakness results`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [
            .weakPasswords,
            .missing2FA
        ])
        let checker = CompromisedPasswordCheckerProtocolMock()
        checker.checkUserIdCandidatesThrowableError1 = PassError.compromisePassword(.invalidResponse)
        let sut = makePaidSut(checker: checker)

        try await sut.refreshSecurityChecks()

        #expect(checker.invokedCheckfunction)
        let stats = try #require(sut.weaknessStats.value)
        #expect(stats.count(for: .weakPassword) == 1)
        #expect(stats.count(for: .missing2FA) == 1)
        #expect(stats.count(for: .compromisedPassword) == 0)
    }

    @Test func `A failing compromised check keeps the previously found breaches`() async throws {
        let items = createEncryptedLoginItems(weakness: [.weakPasswords])
        itemRepository.stubbedGetActiveLogInItemsResult = items
        let checker = CompromisedPasswordCheckerProtocolMock()
        let breached = try #require(items.first)
        checker.stubbedCheckResult = [breached.itemId + breached.shareId]
        let sut = makePaidSut(checker: checker)
        try await sut.refreshSecurityChecks()
        try await waitUntil { sut.weaknessStats.value?.count(for: .compromisedPassword) == 1 }

        checker.checkUserIdCandidatesThrowableError1 = PassError.compromisePassword(.invalidResponse)
        try await sut.refreshSecurityChecks()

        #expect(sut.weaknessStats.value?.count(for: .compromisedPassword) == 1)
    }

    @Test func `A refresh cancelled during the compromised check keeps the previously found breaches`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [.weakPasswords])
        let checker = GatedCompromisedPasswordChecker()
        await checker.open()
        let sut = makePaidSut(checker: checker)
        try await sut.refreshSecurityChecks()
        // The gated checker reports both the weak and the strong login as breached
        try await waitUntil { sut.weaknessStats.value?.count(for: .compromisedPassword) == 2 }

        await checker.close()
        let refresh = Task { try await sut.refreshSecurityChecks() }
        try await waitUntil { await checker.invocationCount == 2 }
        refresh.cancel()
        await checker.open()
        try await refresh.value

        #expect(sut.weaknessStats.value?.count(for: .compromisedPassword) == 2)
    }

    @Test func `Monitor stats report counts compromised passwords from a fresh check`() async throws {
        let items = createEncryptedLoginItems(weakness: [.weakPasswords, .missing2FA])
        itemRepository.stubbedGetActiveLogInItemsResult = items
        let checker = CompromisedPasswordCheckerProtocolMock()
        let breached = try #require(items.first)
        checker.stubbedCheckResult = [breached.itemId + breached.shareId]
        let remote = RemoteBreachDataSourceProtocolMock()
        let sut = makePaidSut(checker: checker, remoteDataSource: remote)

        try await sut.sendUserMonitorStats()

        let sent = try #require(remote.invokedSendUserMonitorStatsParameters)
        #expect(sent.compromisedPasswords == 1)
        #expect(sent.stats.count(for: .weakPassword) == 1)
        #expect(sent.stats.count(for: .missing2FA) == 1)
    }

    @Test func `Monitor stats report omits compromised passwords when the check fails`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [.weakPasswords])
        let checker = CompromisedPasswordCheckerProtocolMock()
        checker.checkUserIdCandidatesThrowableError1 = PassError.compromisePassword(.invalidResponse)
        let remote = RemoteBreachDataSourceProtocolMock()
        let sut = makePaidSut(checker: checker, remoteDataSource: remote)

        try await sut.sendUserMonitorStats()

        let sent = try #require(remote.invokedSendUserMonitorStatsParameters)
        #expect(sent.compromisedPasswords == nil)
        #expect(sent.stats.count(for: .weakPassword) == 1)
    }

    @Test func `A refresh still in flight when reset is called publishes nothing`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [.weakPasswords])
        let checker = GatedCompromisedPasswordChecker()
        let sut = makePaidSut(checker: checker)

        let refresh = Task { try await sut.refreshSecurityChecks() }
        try await waitUntil { await checker.invocationCount == 1 }

        await sut.reset()
        await checker.open()
        try await refresh.value

        #expect(sut.weaknessStats.value == nil)
        #expect(sut.itemsWithSecurityIssues.value.isEmpty)
    }

    @Test func `Local weakness results are published while the compromised check is still running`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [.weakPasswords])
        let checker = GatedCompromisedPasswordChecker()
        let sut = makePaidSut(checker: checker)

        let refresh = Task { try await sut.refreshSecurityChecks() }
        try await waitUntil { await checker.invocationCount == 1 }

        let localStats = try #require(sut.weaknessStats.value)
        #expect(localStats.count(for: .weakPassword) == 1)
        #expect(localStats.count(for: .compromisedPassword) == 0)

        await checker.open()
        try await refresh.value
        // The gated checker reports every candidate (the weak and the strong login) as breached
        try await waitUntil { sut.weaknessStats.value?.count(for: .compromisedPassword) == 2 }
    }

    @Test func `Overlapping compromised checks run one at a time`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [.weakPasswords])
        let checker = GatedCompromisedPasswordChecker()
        let sut = makePaidSut(checker: checker)

        let refresh = Task { try await sut.refreshSecurityChecks() }
        let stats = Task { try await sut.sendUserMonitorStats() }
        try await waitUntil { await checker.invocationCount == 1 }
        for _ in 0..<1_000 {
            await Task.yield()
        }

        await checker.open()
        try await refresh.value
        try await stats.value

        #expect(await checker.maxConcurrentChecks == 1)
    }

    @Test func `Without per-check exclusion monitor stats count fully excluded items`() async throws {
        let items = createEncryptedLoginItems(weakness: [.fullyExcluded])
        let shareId = try #require(items.first).shareId
        let loginData = LogInItemData.mock(username: "test", password: "aaaaa")
        let content = ItemContentProtobufFactory.createItemContentProtobuf(name: "Login",
                                                                           note: "n",
                                                                           itemUuid: UUID().uuidString,
                                                                           data: .login(loginData),
                                                                           customFields: [])
        // 128 = skipReusedPasswordCheck
        let partiallyExcluded = SymmetricallyEncryptedItem
            .random(shareId: shareId,
                    item: .random(flags: 128),
                    encryptedContent: try content.encrypt(symmetricKey: symmetricKeyProviderMockFactory.key))
        itemRepository.stubbedGetActiveLogInItemsResult = items + [partiallyExcluded]
        let checker = CompromisedPasswordCheckerProtocolMock()
        checker.stubbedCheckResult = []
        let remote = RemoteBreachDataSourceProtocolMock()
        let sut = makePaidSut(checker: checker,
                              remoteDataSource: remote,
                              isFeatureEnabled: { $0 != .passMonitorPerCheckExclusion })

        try await sut.refreshSecurityChecks()
        try await sut.sendUserMonitorStats()

        #expect(try #require(sut.weaknessStats.value).excludedItems == 1)
        let sent = try #require(remote.invokedSendUserMonitorStatsParameters)
        #expect(sent.excludedItems == 1)
    }

    @Test func `With per-check exclusion monitor stats count items with nothing left monitored`() async throws {
        // 1 = legacy full exclusion, 32 = skipWeakPasswordCheck, 128 = skipReusedPasswordCheck
        itemRepository.stubbedGetActiveLogInItemsResult = makeWeakLogins(flags: [1, 32, 32, 128])
        let checker = CompromisedPasswordCheckerProtocolMock()
        checker.stubbedCheckResult = []
        let remote = RemoteBreachDataSourceProtocolMock()
        let sut = makePaidSut(checker: checker, remoteDataSource: remote)

        try await sut.refreshSecurityChecks()
        try await sut.sendUserMonitorStats()

        #expect(try #require(sut.weaknessStats.value).excludedItems == 3)
        let sent = try #require(remote.invokedSendUserMonitorStatsParameters)
        #expect(sent.excludedItems == 2)
    }

    func waitUntil(_ condition: () async -> Bool) async throws {
        var spins = 0
        while await !condition(), spins < 10_000 {
            spins += 1
            await Task.yield()
        }
        try #require(await condition())
    }

    @Test func `getItemsWithSamePassword returns the other login sharing the password`() async throws {
        let items = createEncryptedLoginItems(weakness: [.reusedPasswords, .reusedPasswords],
                                              addStrong: false)
        let item = items.first!
        itemRepository.stubbedGetActiveLogInItemsResult = items
        let key = symmetricKeyProviderMockFactory.key

        try await sut.refreshSecurityChecks()
        let reusedItems = try await sut.getItemsWithSamePassword(item: item.getItemContent(symmetricKey: key))
        #expect(reusedItems.count == 1)
        #expect(reusedItems.first! == (try! items.last!.getItemContent(symmetricKey: key)))
    }

    @Test func `getItemsWithSamePassword leaves out an item whose reuse check is ignored`() async throws {
        let shareID = UUID().uuidString
        let key = symmetricKeyProviderMockFactory.key
        shareRepository.stubbedGetSharesResult =
            [SymmetricallyEncryptedShare(encryptedContent: nil, share: .random(shareId: shareID))]

        func make(flags: Int) -> SymmetricallyEncryptedItem {
            let loginData = LogInItemData.mock(username: "test",
                                               password: "Ageless6-Evidence0-Detonator1-Cider4-Synthesis6sdfasdsad")
            let content = ItemContentProtobufFactory.createItemContentProtobuf(name: "Login",
                                                                               note: "n",
                                                                               itemUuid: UUID().uuidString,
                                                                               data: .login(loginData),
                                                                               customFields: [])
            return SymmetricallyEncryptedItem.random(shareId: shareID,
                                                     item: .random(flags: flags),
                                                     encryptedContent: try! content.encrypt(symmetricKey: key))
        }
        // 128 = skipReusedPasswordCheck
        let viewed = make(flags: 0)
        let partner = make(flags: 0)
        let ignored = make(flags: 128)
        itemRepository.stubbedGetActiveLogInItemsResult = [viewed, partner, ignored]

        try await sut.refreshSecurityChecks()
        let reused = try await sut.getItemsWithSamePassword(item: viewed.getItemContent(symmetricKey: key))

        #expect(reused.map(\.ids) == [partner.ids])
    }

    /// IDTEAM-5965: a detail view model can still hold pre-edit content, so the lookup must go by id,
    /// not by the password it was given.
    @Test func `getItemsWithSamePassword resolves the item's current password, ignoring a stale passed-in copy`() async throws {
        let shareID = UUID().uuidString
        let key = symmetricKeyProviderMockFactory.key
        shareRepository.stubbedGetSharesResult =
            [SymmetricallyEncryptedShare(encryptedContent: nil, share: .random(shareId: shareID))]

        let sharedPassword = "Ageless6-Evidence0-Detonator1-Cider4-Synthesis6sdfasdsad"
        let stalePassword = "old-unique-password-never-shared"

        // Stable identity for the edited item so the "stale" and "current" encryptions share ids.
        let viewedItem = Item.random(itemId: "viewed-item-id", flags: 0)

        func encrypt(_ password: String) -> String {
            let loginData = LogInItemData.mock(username: "test", password: password)
            let content = ItemContentProtobufFactory.createItemContentProtobuf(name: "Login",
                                                                               note: "n",
                                                                               itemUuid: UUID().uuidString,
                                                                               data: .login(loginData),
                                                                               customFields: [])
            return try! content.encrypt(symmetricKey: key)
        }

        // Post-edit repository state: the viewed item now shares `sharedPassword` with a partner.
        let viewedCurrent = SymmetricallyEncryptedItem.random(shareId: shareID,
                                                              item: viewedItem,
                                                              encryptedContent: encrypt(sharedPassword))
        let partner = SymmetricallyEncryptedItem.random(shareId: shareID,
                                                        item: .random(flags: 0),
                                                        encryptedContent: encrypt(sharedPassword))
        itemRepository.stubbedGetActiveLogInItemsResult = [viewedCurrent, partner]

        // The caller still holds the pre-edit content: same ids, old (unique) password.
        let staleEncrypted = SymmetricallyEncryptedItem.random(shareId: shareID,
                                                              item: viewedItem,
                                                              encryptedContent: encrypt(stalePassword))
        let staleContent = try staleEncrypted.getItemContent(symmetricKey: key)

        try await sut.refreshSecurityChecks()
        let reused = try await sut.getItemsWithSamePassword(item: staleContent)

        #expect(reused.count == 1)
        #expect(reused.first == (try partner.getItemContent(symmetricKey: key)))
    }

    @Test
    func `item updates refresh the security checks only once monitoring has started`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [.weakPasswords])

        itemRepository.itemsWereUpdated.send()
        // Longer than the 300 ms debounce, so a subscription made without startMonitoring would have fired
        try await Task.sleep(for: .milliseconds(500))
        #expect(itemRepository.invokedGetActiveLogInItemsCount == 0)

        await sut.startMonitoring()
        itemRepository.itemsWereUpdated.send()

        let stats = await sut.weaknessStats.values.first { $0 != nil }
        #expect(stats??.count(for: .weakPassword) == 1)
    }
}

private extension Item {
    static var monitoredMock: Item {
        .random(flags: 0)
    }
    
    static var notMonitoredMock: Item {
        .random(flags: 1)
    }
}
