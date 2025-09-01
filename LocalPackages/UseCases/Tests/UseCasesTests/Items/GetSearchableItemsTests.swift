//
// GetSearchableItemsTests.swift
// Proton Pass - Created on 05/12/2023.
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

@testable import UseCases
import Client
import ClientMocks
import Core
import CoreMocks
import CryptoKit
import Entities
import EntitiesMocks
import UseCasesMocks
import XCTest

class GetSearchableItemsTests: XCTestCase {
    var getSearchableItems: GetSearchableItemsUseCase!
    var itemRepositoryMock: ItemRepositoryProtocolMock!
    var itemRepository: ItemRepositoryProtocolMock!
    var shareRepository: ShareRepositoryProtocolMock!
    var getAllPinnedItems: GetAllPinnedItemsUseCaseMock!
    var symmetricKeyProvider: SymmetricKeyProviderMock!

    override func setUpWithError() throws {
        itemRepositoryMock = ItemRepositoryProtocolMock()
        shareRepository = ShareRepositoryProtocolMock()
        getAllPinnedItems = GetAllPinnedItemsUseCaseMock()
        symmetricKeyProvider = SymmetricKeyProviderMock()
        symmetricKeyProvider.stubbedGetSymmetricKeyResult = try GetSearchableItemsTests.getSymKey()
        getSearchableItems = GetSearchableItems(itemRepository: itemRepositoryMock,
                                                shareRepository: shareRepository,
                                                getAllPinnedItems: getAllPinnedItems,
                                                symmetricKeyProvider: symmetricKeyProvider)
    }

    override func tearDown() {
        getSearchableItems = nil
        itemRepositoryMock = nil
        shareRepository = nil
        getAllPinnedItems = nil
        symmetricKeyProvider = nil
    }

    func testSearchPinItemSuccess() async throws {
        // Given
//        let itemToPin = SymmetricallyEncryptedItem.random()
//        getAllPinnedItems.stubbedExecuteAsyncResult2 = [itemToPin]
//        shareRepository.stubbedGetDecryptedSharesResult = []

        // When
//        do {
//            let result = try await getSearchableItems(for: .pinned)
//
//            // Then
//            XCTAssertTrue(getAllPinnedItems.invokedExecuteAsync)
//            XCTAssertFalse(result.isEmpty)
//        } catch {
//            XCTFail("Unexpected error: \(error)")
//        }
    }

    static func getSymKey() throws -> SymmetricKey {
        let randomData = try Data.random()
        return .init(data: randomData)
    }
}
