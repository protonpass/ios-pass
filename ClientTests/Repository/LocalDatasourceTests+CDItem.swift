//
// LocalDatasourceTests+CDItem.swift
// Proton Pass - Created on 10/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import XCTest

extension LocalDatasourceTests {
    func testInsertItems() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let firstItems = [Item].random(randomElement: .random())
            let secondItems = [Item].random(randomElement: .random())
            let thirdItems = [Item].random(randomElement: .random())
            let givenItems = firstItems + secondItems + thirdItems
            let givenShareId = String.random()

            // When
            try await sut.insertItems(firstItems, shareId: givenShareId)
            try await sut.insertItems(secondItems, shareId: givenShareId)
            try await sut.insertItems(thirdItems, shareId: givenShareId)

            // Then
            let items = try await sut.fetchItems(shareId: givenShareId,
                                                 page: 0,
                                                 pageSize: .max)
            XCTAssertEqual(items.count, givenItems.count)

            let itemIds = Set(items.map { $0.itemID })
            let givenItemIds = Set(givenItems.map { $0.itemID })
            XCTAssertEqual(itemIds, givenItemIds)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }
}
