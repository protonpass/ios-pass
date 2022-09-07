//
// LocalItemKeyDatasourceTests.swift
// Proton Pass - Created on 16/08/2022.
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

final class LocalItemKeyDatasourceTests: XCTestCase {
    let expectationTimeOut: TimeInterval = 3
    var sut: LocalItemKeyDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(container: .Builder.build(name: kProtonPassContainerName,
                                              inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func assertEqual(_ lhs: ItemKey, _ rhs: ItemKey) {
        XCTAssertEqual(lhs.rotationID, rhs.rotationID)
        XCTAssertEqual(lhs.key, rhs.key)
        XCTAssertEqual(lhs.keyPassphrase, rhs.keyPassphrase)
        XCTAssertEqual(lhs.keySignature, rhs.keySignature)
        XCTAssertEqual(lhs.createTime, rhs.createTime)
    }
}

extension LocalItemKeyDatasourceTests {
    func testGetItemKey() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenShareId = String.random()
            let givenRotationId = String.random()
            let givenInsertedItemKey =
            try await sut.givenInsertedItemKey(shareId: givenShareId,
                                               rotationId: givenRotationId)

            // When
            for _ in 0...10 {
                try await sut.upsertItemKeys([.random()], shareId: .random())
            }

            // Then
            let itemKey = try await sut.getItemKey(shareId: givenShareId,
                                                   rotationId: givenRotationId)
            XCTAssertNotNil(itemKey)
            let nonNilItemKey = try XCTUnwrap(itemKey)
            assertEqual(nonNilItemKey, givenInsertedItemKey)
            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testGetItemKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            // 200 itemKeys inserted to the local database
            // pageSize is 70
            let localShareDatasource = LocalShareDatasource(container: sut.container)
            let givenShare = try await localShareDatasource.givenInsertedShare()
            let shareId = givenShare.shareID
            let givenItemKeys = [ItemKey].random(count: 200, randomElement: .random())
            let pageSize = 70

            // When
            try await sut.upsertItemKeys(givenItemKeys, shareId: shareId)

            // Then
            // Should have 3 pages with following counts: 70, 70 & 60
            // 200 in total
            let firstPage = try await sut.getItemKeys(shareId: shareId,
                                                      page: 0,
                                                      pageSize: pageSize)
            XCTAssertEqual(firstPage.count, 70)

            let secondPage = try await sut.getItemKeys(shareId: shareId,
                                                       page: 1,
                                                       pageSize: pageSize)
            XCTAssertEqual(secondPage.count, 70)

            let thirdPage = try await sut.getItemKeys(shareId: shareId,
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

    func testCountItemKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenItemKeys = [ItemKey].random(randomElement: .random())
            let givenShareId = String.random()

            // When
            try await sut.upsertItemKeys(givenItemKeys, shareId: givenShareId)
            // Insert arbitrary item revisions
            for _ in 0...10 {
                let dummyItemKeys = [ItemKey].random(randomElement: .random())
                try await sut.upsertItemKeys(dummyItemKeys, shareId: .random())
            }

            // Then
            let count = try await sut.getItemKeyCount(shareId: givenShareId)
            XCTAssertEqual(count, givenItemKeys.count)
            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

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
            try await sut.upsertItemKeys(firstItemKeys, shareId: givenShareId)
            try await sut.upsertItemKeys(secondItemKeys, shareId: givenShareId)
            try await sut.upsertItemKeys(thirdItemKeys, shareId: givenShareId)

            // Then
            let itemKeys = try await sut.getItemKeys(shareId: givenShareId,
                                                     page: 0,
                                                     pageSize: .max)
            XCTAssertEqual(itemKeys.count, givenItemKeys.count)

            let rotationIds = Set(itemKeys.map { $0.rotationID })
            let givenRotationIds = Set(givenItemKeys.map { $0.rotationID })
            XCTAssertEqual(rotationIds, givenRotationIds)

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
            let givenRotationId = String.random()
            _ = try await sut.givenInsertedItemKey(shareId: givenShareId,
                                                   rotationId: givenRotationId)
            let updatedItemKey = ItemKey.random(rotationId: givenRotationId)

            // When
            try await sut.upsertItemKeys([updatedItemKey], shareId: givenShareId)

            // Then
            let itemKeys = try await sut.getItemKeys(shareId: givenShareId,
                                                     page: 0,
                                                     pageSize: .max)
            XCTAssertEqual(itemKeys.count, 1)
            let itemKey = try XCTUnwrap(itemKeys.first)
            assertEqual(itemKey, updatedItemKey)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testRemoveAllItemKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenFirstShareId = String.random()
            let givenFirstShareItemKeys = [ItemKey].random(randomElement: .random())

            let givenSecondShareId = String.random()
            let givenSecondShareItemKeys = [ItemKey].random(randomElement: .random())

            // When
            try await sut.upsertItemKeys(givenFirstShareItemKeys,
                                         shareId: givenFirstShareId)
            try await sut.upsertItemKeys(givenSecondShareItemKeys,
                                         shareId: givenSecondShareId)

            // Then
            let firstShareItemKeysFirstGet =
            try await sut.getItemKeys(shareId: givenFirstShareId,
                                      page: 0,
                                      pageSize: .max)
            XCTAssertEqual(firstShareItemKeysFirstGet.count,
                           givenFirstShareItemKeys.count)

            let secondShareItemKeysFirstGet =
            try await sut.getItemKeys(shareId: givenSecondShareId,
                                      page: 0,
                                      pageSize: .max)
            XCTAssertEqual(secondShareItemKeysFirstGet.count,
                           givenSecondShareItemKeys.count)

            // When
            try await sut.removeAllItemKeys(shareId: givenFirstShareId)

            // Then
            let firstShareItemKeysSecondGet =
            try await sut.getItemKeys(shareId: givenFirstShareId,
                                      page: 0,
                                      pageSize: .max)
            XCTAssertTrue(firstShareItemKeysSecondGet.isEmpty)

            let secondShareItemKeysSecondGet =
            try await sut.getItemKeys(shareId: givenSecondShareId,
                                      page: 0,
                                      pageSize: .max)
            XCTAssertEqual(secondShareItemKeysSecondGet.count,
                           givenSecondShareItemKeys.count)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }
}

extension LocalItemKeyDatasource {
    func givenInsertedItemKey(shareId: String?, rotationId: String?) async throws -> ItemKey {
        let itemKey = ItemKey.random(rotationId: rotationId)
        try await upsertItemKeys([itemKey], shareId: shareId ?? .random())
        return itemKey
    }
}
