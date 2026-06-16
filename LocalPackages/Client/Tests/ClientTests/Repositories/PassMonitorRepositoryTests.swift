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
        sut = PassMonitorRepository(itemRepository: itemRepository,
                                    shareRepository: shareRepository,
                                    remoteDataSource: RemoteBreachDataSourceProtocolMock(),
                                    symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                                    userManager: userManager)
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

    @Test("PassMonitorRepository operations")
    func testPassMonitorRepositoryTests() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [
            .reusedPasswords,
            .reusedPasswords,
            .weakPasswords,
            .missing2FA,
            .fullyExcluded
        ])

        try await sut.refreshSecurityChecks()

        let state = sut.weaknessStats.value
        // The fully-excluded item (`.fullyExcluded`, monitoringDisabled) is built with a weak
        // password, an empty TOTP and a 2FA-eligible URL — but full exclusion takes precedence
        // (IDTEAM-5965), so it counts ONLY toward the excluded bucket, never the active weak /
        // missing-2FA buckets. Hence weakPasswords == 1 and missing2FA == 1 (the non-excluded items).
        #expect(state.reusedPasswords == 1)
        #expect(state.weakPasswords == 1)
        #expect(state.excludedItems == 1)
        #expect(state.missing2FA == 1)


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
        let state2 = sut.weaknessStats.value
        #expect(state2.reusedPasswords == 1)
        #expect(state2.weakPasswords == 0)
        #expect(state2.excludedItems == 0)
        #expect(state2.missing2FA == 0)

        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [
            .weakPasswords,
            .weakPasswords,
            .weakPasswords
        ])
        try await sut.refreshSecurityChecks()
        
        let itemsWithSecurityReusedWeak = sut.itemsWithSecurityIssues.value
        #expect(itemsWithSecurityReusedWeak.count == 3)
        let state3 = sut.weaknessStats.value
        #expect(state3.reusedPasswords == 1)
        #expect(state3.weakPasswords == 3)
        #expect(state3.excludedItems == 0)
        #expect(state3.missing2FA == 0)
    }
    
    /// Characterization test for IDTEAM-5965: a fully-excluded (`monitoringDisabled`) item whose
    /// password is weak appears ONLY in the excluded bucket — full exclusion takes precedence, so it
    /// does NOT surface as an active weakness. The weakness is still *detected* (it would reappear
    /// if monitoring were re-enabled), but `activeWeaknesses` is empty.
    @Test("Fully-excluded item is excluded only, never an active weakness")
    func testFullyExcludedItemIsExcludedOnly() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = makeFullyExcludedWeakItems()

        try await sut.refreshSecurityChecks()

        let stats = sut.weaknessStats.value
        #expect(stats.excludedItems == 1)
        #expect(stats.weakPasswords == 0)

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
}

private extension Item {
    static var monitoredMock: Item {
        .random(flags: 0)
    }
    
    static var notMonitoredMock: Item {
        .random(flags: 1)
    }
}
