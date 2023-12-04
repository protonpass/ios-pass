//  
// ItemRepositoryTests.swift
// Proton Pass - Created on 01/12/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Entities
import ProtonCoreServices
import XCTest

final class ItemRepositoryTests: XCTestCase {
    var userDataSymmetricKeyProvider: UserDataSymmetricKeyProvider!
    var localDatasource: LocalItemDatasourceProtocol!
    var remoteDatasource: RemoteItemDatasourceProtocol!
    var shareEventIDRepository: ShareEventIDRepositoryProtocol!
    var passKeyManager: PassKeyManagerProtocol!
    var logManager: LogManagerProtocol!
    var sut: ItemRepositoryProtocol!

    override func setUp() {
        super.setUp()
         userDataSymmetricKeyProvider = UserDataSymmetricKeyProviderMock()
         localDatasource = LocalItemDatasourceProtocolMock()
         (localDatasource as? LocalItemDatasourceProtocolMock)?.stubbedGetAllPinnedItemsResult = []
         remoteDatasource = RemoteItemDatasourceProtocolMock()
         shareEventIDRepository = ShareEventIDRepositoryProtocolMock()
         passKeyManager = PassKeyManagerProtocolMock()
         logManager = LogManagerProtocolMock()
    }

    override func tearDown() {
        userDataSymmetricKeyProvider = nil
        localDatasource = nil
        remoteDatasource = nil
        shareEventIDRepository = nil
        passKeyManager = nil
        logManager = nil
        sut = nil
        super.tearDown()
    }
}

// MARK: - Pinned tests

extension ItemRepositoryTests {
    
    func testGetAllPinnedItem() async throws {
        (localDatasource as? LocalItemDatasourceProtocolMock)?.stubbedGetAllPinnedItemsResult = [SymmetricallyEncryptedItem].random(count: 10, randomElement: .random(item:.random(pinned: true)))
        sut = ItemRepository(userDataSymmetricKeyProvider: userDataSymmetricKeyProvider,
                             localDatasource: localDatasource,
                             remoteDatasource: remoteDatasource,
                             shareEventIDRepository: shareEventIDRepository,
                             passKeyManager: passKeyManager,
                             logManager: logManager)
        
        let pinnedItems = try await sut.getAllPinnedItems()
        XCTAssertFalse(pinnedItems.isEmpty)
        XCTAssertEqual(pinnedItems.count, 10)
        XCTAssertEqual(sut.currentlyPinnedItems.value?.count, 10)
        XCTAssertTrue((localDatasource as? LocalItemDatasourceProtocolMock)!.invokedGetAllPinnedItemsfunction)
        XCTAssertEqual((localDatasource as? LocalItemDatasourceProtocolMock)?.invokedGetAllPinnedItemsCount, 2)
    }
}
