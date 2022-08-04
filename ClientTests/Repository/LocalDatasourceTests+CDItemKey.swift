//
// LocalDatasourceTests+CDItemKey.swift
// Proton Pass - Created on 04/08/2022.
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
    func testInsertItemKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let firstItemKeys = [ItemKey].random(randomElement: .random())
            let secondItemKeys = [ItemKey].random(randomElement: .random())
            let thirdItemKeys = [ItemKey].random(randomElement: .random())
            let givenItemKeys = firstItemKeys + secondItemKeys + thirdItemKeys
            let givenShareId = String.random()

            // When
            try await sut.insertItemKeys(firstItemKeys, withShareId: givenShareId)
            try await sut.insertItemKeys(secondItemKeys, withShareId: givenShareId)
            try await sut.insertItemKeys(thirdItemKeys, withShareId: givenShareId)

            // Then
            let itemKeys = try await sut.fetchItemKeys(forShareId: givenShareId,
                                                       page: 0,
                                                       pageSize: Int.max)
            XCTAssertEqual(itemKeys.count, givenItemKeys.count)

            let rotationIds = Set(itemKeys.map { $0.rotationID })
            let givenRotationIds = Set(givenItemKeys.map { $0.rotationID })
            XCTAssertEqual(rotationIds, givenRotationIds)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testFetchItemKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            // 200 itemKeys inserted to the local database
            // pageSize is 70
            let givenShare = try await givenInsertedShare()
            let shareId = givenShare.shareID
            let givenItemKeys = [ItemKey].random(count: 200, randomElement: .random())
            let pageSize = 70

            // When
            try await sut.insertItemKeys(givenItemKeys, withShareId: shareId)

            // Then
            // Should have 3 pages with following counts: 70, 70 & 60
            // 200 in total
            let firstPage = try await sut.fetchItemKeys(forShareId: shareId,
                                                        page: 0,
                                                        pageSize: pageSize)
            XCTAssertEqual(firstPage.count, 70)

            let secondPage = try await sut.fetchItemKeys(forShareId: shareId,
                                                         page: 1,
                                                         pageSize: pageSize)
            XCTAssertEqual(secondPage.count, 70)

            let thirdPage = try await sut.fetchItemKeys(forShareId: shareId,
                                                        page: 2,
                                                        pageSize: pageSize)
            XCTAssertEqual(thirdPage.count, 60)

            // Check that the 3 pages make up the correct set of givenItemKeys
            let fetchedItemKeys = firstPage + secondPage + thirdPage
            let itemKeyRotationIds = Set(fetchedItemKeys.map { $0.rotationID })
            let givenItemKeyRotationIds = Set(givenItemKeys.map { $0.rotationID })
            XCTAssertEqual(itemKeyRotationIds, givenItemKeyRotationIds)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testUpdateItemKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenShareId = String.random()
            let insertedItemKey = try await givenInsertedItemKey(withShareId: givenShareId)
            let updatedItemKey = ItemKey.random(rotationId: insertedItemKey.rotationID)

            // When
            try await sut.insertItemKeys([updatedItemKey], withShareId: givenShareId)

            // Then
            let itemKeys = try await sut.fetchItemKeys(forShareId: givenShareId,
                                                       page: 0,
                                                       pageSize: 100)
            XCTAssertEqual(itemKeys.count, 1)

            let itemKey = try XCTUnwrap(itemKeys.first)
            XCTAssertEqual(itemKey.rotationID, updatedItemKey.rotationID)
            XCTAssertEqual(itemKey.key, updatedItemKey.key)
            XCTAssertEqual(itemKey.keyPassphrase, updatedItemKey.keyPassphrase)
            XCTAssertEqual(itemKey.keySignature, updatedItemKey.keySignature)
            XCTAssertEqual(itemKey.createTime, updatedItemKey.createTime)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func givenInsertedItemKey(withShareId shareId: String) async throws -> ItemKey {
        let itemKey = ItemKey.random()
        try await sut.insertItemKeys([itemKey], withShareId: shareId)
        return itemKey
    }
}
