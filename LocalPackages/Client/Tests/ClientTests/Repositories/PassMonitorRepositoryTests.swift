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

@Suite(.tags(.repository))
struct PassMonitorRepositoryTests {
    let symmetricKeyProviderMockFactory: SymmetricKeyProviderMockFactory
    let itemRepository: ItemRepositoryProtocolMock
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
        sut = PassMonitorRepository(itemRepository: itemRepository,
                                    remoteDataSource: RemoteBreachDataSourceProtocolMock(),
                                    symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                                    userManager: userManager)
    }

    func createEncryptedLoginItems(weakness: [SecurityWeakness], addStrong: Bool = true) -> [SymmetricallyEncryptedItem] {
        var items = [SymmetricallyEncryptedItem]()
        let key = symmetricKeyProviderMockFactory.key

        for weakness in weakness {
            switch weakness {
            case .reusedPasswords:
                let loginData = LogInItemData.mock(password: "Ageless6-Evidence0-Detonator1-Cider4-Synthesis6sdfasdsad")
                let reused1Login = ItemContentProtobufFactory.createItemContentProtobuf(name: "Example Login",
                                                                                        note: "This is a note.",
                                                                                        itemUuid: UUID().uuidString,
                                                                                        data: .login(loginData),
                                                                                        customFields: [])
                items.append(SymmetricallyEncryptedItem.random(item: Item.monitoredMock,
                                                               encryptedContent: try! reused1Login.encrypt(symmetricKey: key)))

            case .weakPasswords:
                let loginData = LogInItemData.mock(username: "test", password: "aaaaa")
                let weakpassLogin = ItemContentProtobufFactory.createItemContentProtobuf(name: "Example Login",
                                                                                         note: "This is a note.",
                                                                                         itemUuid: UUID().uuidString,
                                                                                         data: .login(loginData),
                                                                                         customFields: [])
                items.append(SymmetricallyEncryptedItem.random(item: Item.monitoredMock,
                                                               encryptedContent: try! weakpassLogin.encrypt(symmetricKey: key)))
            case .excludedItems:
                let loginData = LogInItemData.mock(totpUri: "", urls: ["google.com"])
                let nonMonitorLogin = ItemContentProtobufFactory.createItemContentProtobuf(name: "Example Login",
                                                                                           note: "This is a note.",
                                                                                           itemUuid: UUID().uuidString,
                                                                                           data: .login(loginData),
                                                                                           customFields: [])
                items.append(SymmetricallyEncryptedItem.random(item: Item.notMonitoredMock,
                                                               encryptedContent: try! nonMonitorLogin.encrypt(symmetricKey: key)))
            case .missing2FA:
                let loginData = LogInItemData.mock(username: "test", password: "Ageless6-Evidence0-Detonator1-Cider4-Synthesis6sdf", totpUri: "", urls: ["google.com"])
                let no2FALogin = ItemContentProtobufFactory.createItemContentProtobuf(name: "Example Login",
                                                                                      note: "This is a note.",
                                                                                      itemUuid: UUID().uuidString,
                                                                                      data: .login(loginData),
                                                                                      customFields: [])
                items.append(SymmetricallyEncryptedItem.random(item: Item.monitoredMock,
                                                               encryptedContent: try! no2FALogin.encrypt(symmetricKey: key)))
            default:
                continue
            }
        }
        
        if addStrong {
            let loginData = LogInItemData.mock(username: "Strong item", password: "Ageless6-Evidence0-Detonator1-Cider4-Synthesis4")
            let noWeaknessLogin = ItemContentProtobufFactory.createItemContentProtobuf(name: "Example Login",
                                                                                       note: "This is a note.",
                                                                                       itemUuid: UUID().uuidString,
                                                                                       data: .login(loginData),
                                                                                       customFields: [])
            items.append(SymmetricallyEncryptedItem.random(item: Item.monitoredMock,
                                                           encryptedContent: try! noWeaknessLogin.encrypt(symmetricKey: key)))
        }
        
        return items
    }

    @Test("PassMonitorRepository operations")
    func testPassMonitorRepositoryTests() async throws {
        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [.reusedPasswords,.reusedPasswords,.weakPasswords,.missing2FA, .excludedItems])
        try await sut.refreshSecurityChecks()
        
        let state = sut.weaknessStats.value
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

        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [.reusedPasswords,.reusedPasswords,.reusedPasswords,.reusedPasswords])
        try await sut.refreshSecurityChecks()
        
        let itemsWithSecurityOnlyReused = sut.itemsWithSecurityIssues.value
        #expect(itemsWithSecurityOnlyReused.count == 4)
        let state2 = sut.weaknessStats.value
        #expect(state2.reusedPasswords == 1)
        #expect(state2.weakPasswords == 0)
        #expect(state2.excludedItems == 0)
        #expect(state2.missing2FA == 0)

        itemRepository.stubbedGetActiveLogInItemsResult = createEncryptedLoginItems(weakness: [.weakPasswords,.weakPasswords,.weakPasswords])
        try await sut.refreshSecurityChecks()
        
        let itemsWithSecurityReusedWeak = sut.itemsWithSecurityIssues.value
        #expect(itemsWithSecurityReusedWeak.count == 3)
        let state3 = sut.weaknessStats.value
        #expect(state3.reusedPasswords == 1)
        #expect(state3.weakPasswords == 3)
        #expect(state3.excludedItems == 0)
        #expect(state3.missing2FA == 0)
    }
    
    func testPassMonitorRepository_listOfReusedPasswordItems() async throws {
        let items = createEncryptedLoginItems(weakness: [.reusedPasswords, .reusedPasswords], addStrong: false)
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
