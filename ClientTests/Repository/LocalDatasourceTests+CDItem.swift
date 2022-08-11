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

    func testFetchItems() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            // 310 items inserted to the local database
            // pageSize is 90
            let givenShare = try await givenInsertedShare()
            let shareId = givenShare.shareID
            let givenItems = [Item].random(count: 310, randomElement: .random())
            let pageSize = 120

            // When
            try await sut.insertItems(givenItems, shareId: shareId)

            // Then
            // Should have 3 pages with following counts: 120, 120 & 70
            // 310 in total
            let firstPage = try await sut.fetchItems(shareId: shareId,
                                                     page: 0,
                                                     pageSize: pageSize)
            XCTAssertEqual(firstPage.count, 120)

            let secondPage = try await sut.fetchItems(shareId: shareId,
                                                      page: 1,
                                                      pageSize: pageSize)
            XCTAssertEqual(secondPage.count, 120)

            let thirdPage = try await sut.fetchItems(shareId: shareId,
                                                     page: 2,
                                                     pageSize: pageSize)
            XCTAssertEqual(thirdPage.count, 70)

            // Check that the 3 pages make up the correct set of givenItems
            let items = firstPage + secondPage + thirdPage
            let itemIds = Set(items.map { $0.itemID })
            let givenItemIds = Set(givenItems.map { $0.itemID })
            XCTAssertEqual(itemIds, givenItemIds)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testUpdateItems() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenShareId = String.random()
            let insertedItem = try await givenInsertedItem(shareId: givenShareId)
            let updatedItem = Item.random(itemId: insertedItem.itemID)

            // When
            try await sut.insertItems([updatedItem], shareId: givenShareId)

            // Then
            let items = try await sut.fetchItems(shareId: givenShareId,
                                                 page: 0,
                                                 pageSize: .max)
            XCTAssertEqual(items.count, 1)

            let item = try XCTUnwrap(items.first)
            XCTAssertEqual(item.itemID, updatedItem.itemID)
            XCTAssertEqual(item.revision, updatedItem.revision)
            XCTAssertEqual(item.contentFormatVersion, updatedItem.contentFormatVersion)
            XCTAssertEqual(item.rotationID, updatedItem.rotationID)
            XCTAssertEqual(item.content, updatedItem.content)
            XCTAssertEqual(item.userSignature, updatedItem.userSignature)
            XCTAssertEqual(item.itemKeySignature, updatedItem.itemKeySignature)
            XCTAssertEqual(item.state, updatedItem.state)
            XCTAssertEqual(item.signatureEmail, updatedItem.signatureEmail)
            XCTAssertEqual(item.aliasEmail, updatedItem.aliasEmail)
            XCTAssertEqual(item.createTime, updatedItem.createTime)
            XCTAssertEqual(item.modifyTime, updatedItem.modifyTime)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func givenInsertedItem(shareId: String) async throws -> Item {
        let item = Item.random()
        try await sut.insertItems([item], shareId: shareId)
        return item
    }

    func testCountItems() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenItems = [Item].random(randomElement: .random())
            let givenShareId = String.random()

            // When
            try await sut.insertItems(givenItems, shareId: givenShareId)
            // Insert arbitrary items
            for _ in 0...10 {
                let dummyItems = [Item].random(randomElement: .random())
                try await sut.insertItems(dummyItems, shareId: .random())
            }

            // Then
            let count = try await sut.getItemsCount(shareId: givenShareId)
            XCTAssertEqual(count, givenItems.count)
            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }
}
