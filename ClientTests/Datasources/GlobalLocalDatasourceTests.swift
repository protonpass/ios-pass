//
// GlobalLocalDatasourceTests.swift
// Proton Pass - Created on 17/08/2022.
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

// swiftlint:disable function_body_length
final class GlobalLocalDatasourceTests: XCTestCase {
    let expectationTimeOut: TimeInterval = 10
    var sut: GlobalLocalDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(container: .Builder.build(name: kProtonPassContainerName,
                                              inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension GlobalLocalDatasourceTests {
    func testRemoveAllData() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task { @MainActor in
            // Given
            // First set of data
            let firstUserId = String.random()
            let firstShareIds = [String].random(randomElement: .random())
            let firstItemCount = Int.random(in: 100...500)
            try await populateData(userId: firstUserId,
                                   shareIds: firstShareIds,
                                   itemCount: firstItemCount)

            let firstSharesFirstGet =
            try await sut.localShareDatasource.getAllShares(userId: firstUserId)
            XCTAssertEqual(firstSharesFirstGet.count, firstShareIds.count)

            for shareId in firstShareIds {
                let itemKeys =
                try await sut.localItemKeyDatasource.getItemKeys(shareId: shareId)
                XCTAssertFalse(itemKeys.isEmpty)

                let vaultKeys =
                try await sut.localVaultKeyDatasource.getVaultKeys(shareId: shareId)
                XCTAssertFalse(vaultKeys.isEmpty)

                let itemCount = try await sut.localItemDatasource.getItemCount(shareId: shareId)
                XCTAssertEqual(itemCount, firstItemCount)
            }

            // Second set of data
            let secondUserId = String.random()
            let secondShareIds = [String].random(randomElement: .random())
            let secondItemCount = Int.random(in: 100...500)
            try await populateData(userId: secondUserId,
                                   shareIds: secondShareIds,
                                   itemCount: secondItemCount)

            let secondSharesFirstGet =
            try await sut.localShareDatasource.getAllShares(userId: secondUserId)
            XCTAssertEqual(secondSharesFirstGet.count, secondShareIds.count)

            for shareId in secondShareIds {
                let itemKeys =
                try await sut.localItemKeyDatasource.getItemKeys(shareId: shareId)
                XCTAssertFalse(itemKeys.isEmpty)

                let vaultKeys =
                try await sut.localVaultKeyDatasource.getVaultKeys(shareId: shareId)
                XCTAssertFalse(vaultKeys.isEmpty)

                let itemCount = try await sut.localItemDatasource.getItemCount(shareId: shareId)
                XCTAssertEqual(itemCount, secondItemCount)
            }

            // When
            // Remove first set of data
            try await sut.removeAllData(userId: firstUserId)

            // Then
            // First set of data should be null
            let firstSharesSecondGet =
            try await sut.localShareDatasource.getAllShares(userId: firstUserId)
            XCTAssertTrue(firstSharesSecondGet.isEmpty)

            for shareId in firstShareIds {
                let itemKeys =
                try await sut.localItemKeyDatasource.getItemKeys(shareId: shareId)
                XCTAssertTrue(itemKeys.isEmpty)

                let vaultKeys =
                try await sut.localVaultKeyDatasource.getVaultKeys(shareId: shareId)
                XCTAssertTrue(vaultKeys.isEmpty)

                let itemCount = try await sut.localItemDatasource.getItemCount(shareId: shareId)
                XCTAssertEqual(itemCount, 0)
            }

            // Second set of data should be intact
            let secondSharesSecondGet =
            try await sut.localShareDatasource.getAllShares(userId: secondUserId)
            XCTAssertEqual(secondSharesSecondGet.count, secondShareIds.count)

            for shareId in secondShareIds {
                let itemKeys =
                try await sut.localItemKeyDatasource.getItemKeys(shareId: shareId)
                XCTAssertFalse(itemKeys.isEmpty)

                let vaultKeys =
                try await sut.localVaultKeyDatasource.getVaultKeys(shareId: shareId)
                XCTAssertFalse(vaultKeys.isEmpty)

                let itemCount = try await sut.localItemDatasource.getItemCount(shareId: shareId)
                XCTAssertEqual(itemCount, secondItemCount)
            }

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func populateData(userId: String, shareIds: [String], itemCount: Int) async throws {
        // Populate item keys, vault keys & item revisions
        // to a list of shares with given ids
        for shareId in shareIds {
            let share = Share.random(shareId: shareId)
            try await sut.localShareDatasource.upsertShares([share], userId: userId)

            let itemKeys = [ItemKey].random(randomElement: .random())
            try await sut.localItemKeyDatasource.upsertItemKeys(itemKeys, shareId: shareId)

            let vaultKeys = [VaultKey].random(randomElement: .random())
            try await sut.localVaultKeyDatasource.upsertVaultKeys(vaultKeys, shareId: shareId)

            let itemRevisions = [ItemRevision].random(count: itemCount, randomElement: .random())
            try await sut.localItemDatasource.upsertItems(itemRevisions.map { .init(shareId: shareId,
                                                                                    item: $0,
                                                                                    encryptedContent: .random(),
                                                                                    type: .random()) })
        }
    }
}
