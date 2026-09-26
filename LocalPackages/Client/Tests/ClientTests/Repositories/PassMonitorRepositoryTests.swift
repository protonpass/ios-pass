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
        // Guard against the SUT's init-time `setup()` task calling `getShares` before a test body
        // sets a stub (the generated mock force-unwraps `stubbedGetSharesResult`). Mirrors the
        // `itemRepository` default above.
        shareRepository.stubbedGetSharesResult = []
        // Free plan => compromised-password detection (a paid feature) is skipped, so these tests
        // exercise only the local weakness checks.
        let accessRepository = AccessRepositoryProtocolMock()
        accessRepository.stubbedGetAccessResult = UserAccess(userId: "test",
                                                             access: Access(plan: .init(type: "free",
                                                                                        internalName: "free",
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
        sut = PassMonitorRepository(itemRepository: itemRepository,
                                    shareRepository: shareRepository,
                                    remoteDataSource: RemoteBreachDataSourceProtocolMock(),
                                    symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                                    userManager: userManager,
                                    accessRepository: accessRepository,
                                    compromisedPasswordChecker: CompromisedPasswordCheckerProtocolMock())
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

    @Test
    func `PassMonitorRepository operations`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [
            .reusedPasswords,
            .reusedPasswords,
            .weakPasswords,
            .missing2FA,
            .fullyExcluded
        ])

        try await sut.refreshSecurityChecks()

        let state = try #require(sut.weaknessStats.value)
        // The fully-excluded item (`.fullyExcluded`, monitoringDisabled) is built with a weak
        // password, an empty TOTP and a 2FA-eligible URL — but full exclusion takes precedence
        // (IDTEAM-5965), so it counts ONLY toward the excluded bucket, never the active weak /
        // missing-2FA buckets. Hence weakPasswords == 1 and missing2FA == 1 (the non-excluded items).
        #expect(state.count(for: .reusedPassword) == 1)
        #expect(state.count(for: .weakPassword) == 1)
        #expect(state.excludedItems == 1)
        #expect(state.count(for: .missing2FA) == 1)


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
    
    @Test
    func `Items sharing a password share a reuse group, unique passwords have none`() async throws {
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

    /// Characterization test for IDTEAM-5965: a fully-excluded (`monitoringDisabled`) item whose
    /// password is weak appears ONLY in the excluded bucket — full exclusion takes precedence, so it
    /// does NOT surface as an active weakness. The weakness is still *detected* (it would reappear
    /// if monitoring were re-enabled), but `activeWeaknesses` is empty.
    @Test
    func `Fully-excluded item is excluded only, never an active weakness`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = makeFullyExcludedWeakItems()

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
    }

    /// A single fully-excluded (`monitoringDisabled`) login whose password is weak.
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

    @Test
    func `Reuse-suppressed item wont counts; its partner is removed from flagged`() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = makeReusePairOneSuppressed()

        try await sut.refreshSecurityChecks()
        let affected = sut.itemsWithSecurityIssues.value
    
        let suppressed = try #require(affected.first { $0.suppressedChecks.contains(.reusedPassword) })
        #expect(affected.count == 1)

        // Suppressed item: not detected as reused.
        #expect(suppressed.detected.isEmpty)
        #expect(!suppressed.activeWeaknesses.contains(.reusedPassword))
        #expect(suppressed.isExcludedItem)
    }

    /// Two logins sharing the SAME strong password; the first has the reused-password check
    /// suppressed (flag `skipReusedPasswordCheck`, rawValue 1 << 7 = 128), the second is normally
    /// monitored.
    func makeReusePairOneSuppressed() -> [SymmetricallyEncryptedItem] {
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
        return [make(flags: 128), make(flags: 0)]
    }

    func testPassMonitorRepository_listOfReusedPasswordItems() async throws {
        let items = createEncryptedLoginItems(weakness: [.reusedPasswords, .reusedPasswords],
                                              addStrong: false)
        let item = items.first!
        itemRepository.stubbedGetActiveLogInItemsResult = items
        let key = symmetricKeyProviderMockFactory.key

        let reusedItems = try await sut.getItemsWithSamePassword(item: item.getItemContent(symmetricKey: key))
        #expect(reusedItems.count == 1)
        #expect(reusedItems.first! == (try! items.last!.getItemContent(symmetricKey: key)))
    }

    /// Regression for IDTEAM-5965: the reused-password count must reflect the item's CURRENT
    /// password, not a stale `ItemContent` a long-lived detail view model may still hold after an
    /// edit. Here the repository already reflects the post-edit state (the viewed item shares its new
    /// password with a partner), but the caller passes the PRE-edit content (same ids, old unique
    /// password). The lookup must resolve the current password by id and still find the partner —
    /// otherwise the UI shows "Reused password" with "0 other logins use this password".
    @Test
    func `getItemsWithSamePassword resolves the item's current password, ignoring a stale passed-in copy`() async throws {
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

        let reused = try await sut.getItemsWithSamePassword(item: staleContent)

        #expect(reused.count == 1)
        #expect(reused.first == (try partner.getItemContent(symmetricKey: key)))
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
