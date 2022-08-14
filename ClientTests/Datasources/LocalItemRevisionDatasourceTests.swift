//
// LocalItemRevisionDatasourceTests.swift
// Proton Pass - Created on 14/08/2022.
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

final class LocalItemRevisionDatasourceTests: XCTestCase {
    let expectationTimeOut: TimeInterval = 3
    var sut: LocalItemRevisionDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(container: .Builder.build(name: kProtonPassContainerName,
                                              inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func assertEqual(_ lhs: ItemRevision, _ rhs: ItemRevision) {
        XCTAssertEqual(lhs.itemID, rhs.itemID)
        XCTAssertEqual(lhs.revision, rhs.revision)
        XCTAssertEqual(lhs.contentFormatVersion, rhs.contentFormatVersion)
        XCTAssertEqual(lhs.rotationID, rhs.rotationID)
        XCTAssertEqual(lhs.content, rhs.content)
        XCTAssertEqual(lhs.userSignature, rhs.userSignature)
        XCTAssertEqual(lhs.itemKeySignature, rhs.itemKeySignature)
        XCTAssertEqual(lhs.state, rhs.state)
        XCTAssertEqual(lhs.signatureEmail, rhs.signatureEmail)
        XCTAssertEqual(lhs.aliasEmail, rhs.aliasEmail)
        XCTAssertEqual(lhs.createTime, rhs.createTime)
        XCTAssertEqual(lhs.modifyTime, rhs.modifyTime)
    }
}

extension LocalItemRevisionDatasourceTests {
    func testGetItemRevision() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenShareId = String.random()
            let givenItemId = String.random()
            let givenInsertItemRevision =
            try await sut.givenInsertedItemRevision(itemId: givenItemId,
                                                    shareId: givenShareId)

            // When
            for _ in 0...10 {
                try await sut.upsertItemRevisions([.random()], shareId: .random())
            }

            // Then
            let itemRevision = try await sut.getItemRevision(shareId: givenShareId,
                                                             itemId: givenItemId)
            XCTAssertNotNil(itemRevision)
            let nonNilItemRevision = try XCTUnwrap(itemRevision)
            assertEqual(nonNilItemRevision, givenInsertItemRevision)
            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testGetItemRevisions() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            // 310 items inserted to the local database
            // pageSize is 90
            let localShareDatasource = LocalShareDatasource(container: sut.container)
            let givenShare = try await localShareDatasource.givenInsertShare(userId: nil)
            let shareId = givenShare.shareID
            let givenItemRevisions = [ItemRevision].random(count: 310,
                                                           randomElement: .random())
            let pageSize = 120

            // When
            try await sut.upsertItemRevisions(givenItemRevisions, shareId: shareId)

            // Then
            // Should have 3 pages with following counts: 120, 120 & 70
            // 310 in total
            let firstPage = try await sut.getItemRevisions(shareId: shareId,
                                                           page: 0,
                                                           pageSize: pageSize)
            XCTAssertEqual(firstPage.revisionsData.count, 120)
            XCTAssertEqual(firstPage.total, 310)

            let secondPage = try await sut.getItemRevisions(shareId: shareId,
                                                            page: 1,
                                                            pageSize: pageSize)
            XCTAssertEqual(secondPage.revisionsData.count, 120)
            XCTAssertEqual(secondPage.total, 310)

            let thirdPage = try await sut.getItemRevisions(shareId: shareId,
                                                           page: 2,
                                                           pageSize: pageSize)
            XCTAssertEqual(thirdPage.revisionsData.count, 70)
            XCTAssertEqual(thirdPage.total, 310)

            // Check that the 3 pages make up the correct set of givenItems
            let itemRevisions = firstPage.revisionsData + secondPage.revisionsData + thirdPage.revisionsData
            let itemRevisionIds = Set(itemRevisions.map { $0.itemID })
            let givenItemRevisionIds = Set(givenItemRevisions.map { $0.itemID })
            XCTAssertEqual(itemRevisionIds, givenItemRevisionIds)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }
}

extension LocalItemRevisionDatasource {
    func givenInsertedItemRevision(itemId: String?,
                                   shareId: String?) async throws -> ItemRevision {
        let itemRevision = ItemRevision.random(itemId: itemId ?? .random())
        try await upsertItemRevisions([itemRevision], shareId: shareId ?? .random())
        return itemRevision
    }
}
