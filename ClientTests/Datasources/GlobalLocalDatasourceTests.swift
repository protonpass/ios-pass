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
    let expectationTimeOut: TimeInterval = 3
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
        Task {
            // Given
            // First set of data
            let firstUserId = String.random()
            let firstShareIds = [String].random(randomElement: .random())
            try await populateData(userId: firstUserId,
                                   shareIds: firstShareIds)

            let firstSharesFirstGet =
            try await sut.localShareDatasource.getAllShares(userId: firstUserId)
            XCTAssertEqual(firstSharesFirstGet.count, firstShareIds.count)

            for shareId in firstShareIds {
                let itemKeys =
                try await sut.localItemKeyDatasource.getItemKeys(shareId: shareId,
                                                                 page: 0,
                                                                 pageSize: .max)
                XCTAssertFalse(itemKeys.isEmpty)

                let vaultKeys =
                try await sut.localVaultKeyDatasource.getVaultKeys(shareId: shareId,
                                                                   page: 0,
                                                                   pageSize: .max)
                XCTAssertFalse(vaultKeys.isEmpty)

                let itemRevisions = try await sut.localItemRevisionDatasource.getItemRevisions(shareId: shareId)
                XCTAssertFalse(itemRevisions.isEmpty)
            }

            // Second set of data
            let secondUserId = String.random()
            let secondShareIds = [String].random(randomElement: .random())
            try await populateData(userId: secondUserId,
                                   shareIds: secondShareIds)

            let secondSharesFirstGet =
            try await sut.localShareDatasource.getAllShares(userId: secondUserId)
            XCTAssertEqual(secondSharesFirstGet.count, secondShareIds.count)

            for shareId in secondShareIds {
                let itemKeys =
                try await sut.localItemKeyDatasource.getItemKeys(shareId: shareId,
                                                                 page: 0,
                                                                 pageSize: .max)
                XCTAssertFalse(itemKeys.isEmpty)

                let vaultKeys =
                try await sut.localVaultKeyDatasource.getVaultKeys(shareId: shareId,
                                                                   page: 0,
                                                                   pageSize: .max)
                XCTAssertFalse(vaultKeys.isEmpty)

                let itemRevisions = try await sut.localItemRevisionDatasource.getItemRevisions(shareId: shareId)
                XCTAssertFalse(itemRevisions.isEmpty)
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
                try await sut.localItemKeyDatasource.getItemKeys(shareId: shareId,
                                                                 page: 0,
                                                                 pageSize: .max)
                XCTAssertTrue(itemKeys.isEmpty)

                let vaultKeys =
                try await sut.localVaultKeyDatasource.getVaultKeys(shareId: shareId,
                                                                   page: 0,
                                                                   pageSize: .max)
                XCTAssertTrue(vaultKeys.isEmpty)

                let itemRevisions = try await sut.localItemRevisionDatasource.getItemRevisions(shareId: shareId)
                XCTAssertTrue(itemRevisions.isEmpty)
            }

            // Second set of data should be intact
            let secondSharesSecondGet =
            try await sut.localShareDatasource.getAllShares(userId: secondUserId)
            XCTAssertEqual(secondSharesSecondGet.count, secondShareIds.count)

            for shareId in secondShareIds {
                let itemKeys =
                try await sut.localItemKeyDatasource.getItemKeys(shareId: shareId,
                                                                 page: 0,
                                                                 pageSize: .max)
                XCTAssertFalse(itemKeys.isEmpty)

                let vaultKeys =
                try await sut.localVaultKeyDatasource.getVaultKeys(shareId: shareId,
                                                                   page: 0,
                                                                   pageSize: .max)
                XCTAssertFalse(vaultKeys.isEmpty)

                let itemRevisions = try await sut.localItemRevisionDatasource.getItemRevisions(shareId: shareId)
                XCTAssertFalse(itemRevisions.isEmpty)
            }

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func populateData(userId: String, shareIds: [String]) async throws {
        // Populate item keys, vault keys & item revisions
        // to a list of shares with given ids
        for shareId in shareIds {
            let share = Share.random(shareId: shareId)
            try await sut.localShareDatasource.upsertShares([share], userId: userId)

            let itemKeys = [ItemKey].random(randomElement: .random())
            try await sut.localItemKeyDatasource.upsertItemKeys(itemKeys, shareId: shareId)

            let vaultKeys = [VaultKey].random(randomElement: .random())
            try await sut.localVaultKeyDatasource.upsertVaultKeys(vaultKeys, shareId: shareId)

            let itemRevisions = [ItemRevision].random(randomElement: .random())
            try await sut.localItemRevisionDatasource.upsertItemRevisions(itemRevisions,
                                                                          shareId: shareId)
        }
    }
}
