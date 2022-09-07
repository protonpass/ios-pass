//
// LocalVaultKeyDatasourceTests.swift
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

final class LocalVaultKeyDatasourceTests: XCTestCase {
    let expectationTimeOut: TimeInterval = 3
    var sut: LocalVaultKeyDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(container: .Builder.build(name: kProtonPassContainerName,
                                              inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func assertEqual(_ lhs: VaultKey, _ rhs: VaultKey) {
        XCTAssertEqual(lhs.rotationID, rhs.rotationID)
        XCTAssertEqual(lhs.rotation, rhs.rotation)
        XCTAssertEqual(lhs.key, rhs.key)
        XCTAssertEqual(lhs.keyPassphrase, rhs.keyPassphrase)
        XCTAssertEqual(lhs.keySignature, rhs.keySignature)
        XCTAssertEqual(lhs.createTime, rhs.createTime)
    }
}

extension LocalVaultKeyDatasourceTests {
    func testGetVaultKey() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenShareId = String.random()
            let givenRotationId = String.random()
            let givenInsertedVaultKey =
            try await sut.givenInsertedVaultKey(shareId: givenShareId,
                                                rotationId: givenRotationId)

            // When
            for _ in 0...10 {
                try await sut.upsertVaultKeys([.random()], shareId: .random())
            }

            // Then
            let vaultKey = try await sut.getVaultKey(shareId: givenShareId,
                                                     rotationId: givenRotationId)
            XCTAssertNotNil(vaultKey)
            let nonNilVaultKey = try XCTUnwrap(vaultKey)
            assertEqual(nonNilVaultKey, givenInsertedVaultKey)
            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testGetVaultKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            // 200 itemKeys inserted to the local database
            // pageSize is 70
            let localShareDatasource = LocalShareDatasource(container: sut.container)
            let givenShare = try await localShareDatasource.givenInsertedShare()
            let shareId = givenShare.shareID
            let givenVaultKeys = [VaultKey].random(count: 200, randomElement: .random())
            let pageSize = 70

            // When
            try await sut.upsertVaultKeys(givenVaultKeys, shareId: shareId)

            // Then
            // Should have 3 pages with following counts: 70, 70 & 60
            // 200 in total
            let firstPage = try await sut.getVaultKeys(shareId: shareId,
                                                       page: 0,
                                                       pageSize: pageSize)
            XCTAssertEqual(firstPage.count, 70)

            let secondPage = try await sut.getVaultKeys(shareId: shareId,
                                                        page: 1,
                                                        pageSize: pageSize)
            XCTAssertEqual(secondPage.count, 70)

            let thirdPage = try await sut.getVaultKeys(shareId: shareId,
                                                       page: 2,
                                                       pageSize: pageSize)
            XCTAssertEqual(thirdPage.count, 60)

            // Check that the 3 pages make up the correct set of givenItemKeys
            let fetchedVaultKeys = firstPage + secondPage + thirdPage
            let vaultKeyRotationIds = Set(fetchedVaultKeys.map { $0.rotationID })
            let givenItemKeyRotationIds = Set(givenVaultKeys.map { $0.rotationID })
            XCTAssertEqual(vaultKeyRotationIds, givenItemKeyRotationIds)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testCountVaultKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenVaultKeys = [VaultKey].random(randomElement: .random())
            let givenShareId = String.random()

            // When
            try await sut.upsertVaultKeys(givenVaultKeys, shareId: givenShareId)
            // Insert arbitrary item revisions
            for _ in 0...10 {
                let dummyVaultKeys = [VaultKey].random(randomElement: .random())
                try await sut.upsertVaultKeys(dummyVaultKeys, shareId: .random())
            }

            // Then
            let count = try await sut.getVaultKeyCount(shareId: givenShareId)
            XCTAssertEqual(count, givenVaultKeys.count)
            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testInsertVaultKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let firstVaultKeys = [VaultKey].random(randomElement: .random())
            let secondVaultKeys = [VaultKey].random(randomElement: .random())
            let thirdVaultKeys = [VaultKey].random(randomElement: .random())
            let givenVaultKeys = firstVaultKeys + secondVaultKeys + thirdVaultKeys
            let givenShareId = String.random()

            // When
            try await sut.upsertVaultKeys(firstVaultKeys, shareId: givenShareId)
            try await sut.upsertVaultKeys(secondVaultKeys, shareId: givenShareId)
            try await sut.upsertVaultKeys(thirdVaultKeys, shareId: givenShareId)

            // Then
            let vaultKeys = try await sut.getVaultKeys(shareId: givenShareId,
                                                       page: 0,
                                                       pageSize: .max)
            XCTAssertEqual(vaultKeys.count, givenVaultKeys.count)

            let rotationIds = Set(vaultKeys.map { $0.rotationID })
            let givenRotationIds = Set(givenVaultKeys.map { $0.rotationID })
            XCTAssertEqual(rotationIds, givenRotationIds)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testUpdateVaultKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenShareId = String.random()
            let givenRotationId = String.random()
            _ = try await sut.givenInsertedVaultKey(shareId: givenShareId,
                                                    rotationId: givenRotationId)
            let updatedVaultKey = VaultKey.random(rotationId: givenRotationId)

            // When
            try await sut.upsertVaultKeys([updatedVaultKey], shareId: givenShareId)

            // Then
            let vaultKeys = try await sut.getVaultKeys(shareId: givenShareId,
                                                       page: 0,
                                                       pageSize: .max)
            XCTAssertEqual(vaultKeys.count, 1)
            let vaultKey = try XCTUnwrap(vaultKeys.first)
            assertEqual(vaultKey, updatedVaultKey)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testRemoveAllVaultKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenFirstShareId = String.random()
            let givenFirstShareVaultKeys = [VaultKey].random(randomElement: .random())

            let givenSecondShareId = String.random()
            let givenSecondShareVaultKeys = [VaultKey].random(randomElement: .random())

            // When
            try await sut.upsertVaultKeys(givenFirstShareVaultKeys,
                                          shareId: givenFirstShareId)
            try await sut.upsertVaultKeys(givenSecondShareVaultKeys,
                                          shareId: givenSecondShareId)

            // Then
            let firstShareVaultKeysFirstGet =
            try await sut.getVaultKeys(shareId: givenFirstShareId,
                                       page: 0,
                                       pageSize: .max)
            XCTAssertEqual(firstShareVaultKeysFirstGet.count,
                           givenFirstShareVaultKeys.count)

            let secondShareVaultKeysFirstGet =
            try await sut.getVaultKeys(shareId: givenSecondShareId,
                                       page: 0,
                                       pageSize: .max)
            XCTAssertEqual(secondShareVaultKeysFirstGet.count,
                           givenSecondShareVaultKeys.count)

            // When
            try await sut.removeAllVaultKeys(shareId: givenFirstShareId)

            // Then
            let firstShareVaultKeysSecondGet =
            try await sut.getVaultKeys(shareId: givenFirstShareId,
                                       page: 0,
                                       pageSize: .max)
            XCTAssertTrue(firstShareVaultKeysSecondGet.isEmpty)

            let secondShareVaultKeysSecondGet =
            try await sut.getVaultKeys(shareId: givenSecondShareId,
                                       page: 0,
                                       pageSize: .max)
            XCTAssertEqual(secondShareVaultKeysSecondGet.count,
                           givenSecondShareVaultKeys.count)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }
}

extension LocalVaultKeyDatasource {
    func givenInsertedVaultKey(shareId: String?, rotationId: String?) async throws -> VaultKey {
        let vaultKey = VaultKey.random(rotationId: rotationId)
        try await upsertVaultKeys([vaultKey], shareId: shareId ?? .random())
        return vaultKey
    }
}
