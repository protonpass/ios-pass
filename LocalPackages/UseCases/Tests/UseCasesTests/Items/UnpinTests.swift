//
// UnpinTests.swift
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
import Entities
import EntitiesMocks
import XCTest

class UnpinTests: XCTestCase {
    var unpinItemUseCase: UnpinItemUseCase!
    var itemRepositoryMock: ItemRepositoryProtocolMock!

    override func setUpWithError() throws {
        itemRepositoryMock = ItemRepositoryProtocolMock()
        unpinItemUseCase = UnpinItem(itemRepository: itemRepositoryMock, logManager: LogManagerProtocolMock())
    }

    override func tearDownWithError() throws {
        unpinItemUseCase = nil
        itemRepositoryMock = nil
    }

    func testPinItemSuccess() async throws {
        // Given
        let itemToPin = TestItem(shareId: "sharedId", itemId: "Item id")
        let encryptedItem = SymmetricallyEncryptedItem.random()
        itemRepositoryMock.stubbedUnpinItemResult = encryptedItem

        // When
        do {
            let result = try await unpinItemUseCase(item: itemToPin)

            // Then
            XCTAssertTrue(itemRepositoryMock.invokedUnpinItemfunction)
            guard let item = itemRepositoryMock.invokedUnpinItemParameters?.item as? TestItem else {
                XCTFail("Should be an TestItem")
                return
            }
            XCTAssertEqual(item, itemToPin)
            XCTAssertEqual(result, encryptedItem)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
