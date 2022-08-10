//
// LocalDatasourceTests+CDVaultKey.swift
// Proton Pass - Created on 03/08/2022.
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
            try await sut.insertVaultKeys(firstVaultKeys, shareId: givenShareId)
            try await sut.insertVaultKeys(secondVaultKeys, shareId: givenShareId)
            try await sut.insertVaultKeys(thirdVaultKeys, shareId: givenShareId)

            // Then
            let vaultKeys = try await sut.fetchVaultKeys(shareId: givenShareId,
                                                         page: 0,
                                                         pageSize: Int.max)
            XCTAssertEqual(vaultKeys.count, givenVaultKeys.count)

            let rotationIds = Set(vaultKeys.map { $0.rotationID })
            let givenRotationIds = Set(givenVaultKeys.map { $0.rotationID })
            XCTAssertEqual(rotationIds, givenRotationIds)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func testFetchVaultKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            // 120 vaultKeys inserted to the local database
            // pageSize is 50
            let givenShare = try await givenInsertedShare()
            let shareId = givenShare.shareID
            let givenVaultKeys = [VaultKey].random(count: 120, randomElement: .random())
            let pageSize = 50

            // When
            try await sut.insertVaultKeys(givenVaultKeys, shareId: shareId)

            // Then
            // Should have 3 pages with following counts: 50, 50 & 20
            // 120 in total
            let firstPage = try await sut.fetchVaultKeys(shareId: shareId,
                                                         page: 0,
                                                         pageSize: pageSize)
            XCTAssertEqual(firstPage.count, 50)

            let secondPage = try await sut.fetchVaultKeys(shareId: shareId,
                                                          page: 1,
                                                          pageSize: pageSize)
            XCTAssertEqual(secondPage.count, 50)

            let thirdPage = try await sut.fetchVaultKeys(shareId: shareId,
                                                         page: 2,
                                                         pageSize: pageSize)
            XCTAssertEqual(thirdPage.count, 20)

            // Check that the 3 pages make up the correct set of givenVaultKeys
            let fetchedVaultKeys = firstPage + secondPage + thirdPage
            let vaultKeyRotationIds = Set(fetchedVaultKeys.map { $0.rotationID })
            let givenVaultKeyRotationIds = Set(givenVaultKeys.map { $0.rotationID })
            XCTAssertEqual(vaultKeyRotationIds, givenVaultKeyRotationIds)

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
            let insertedVaultKey = try await givenInsertedVaultKey(shareId: givenShareId)
            let updatedVaultKey = VaultKey.random(rotationId: insertedVaultKey.rotationID)

            // When
            try await sut.insertVaultKeys([updatedVaultKey], shareId: givenShareId)

            // Then
            let vaultKeys = try await sut.fetchVaultKeys(shareId: givenShareId,
                                                         page: 0,
                                                         pageSize: .max)
            XCTAssertEqual(vaultKeys.count, 1)

            let vaultKey = try XCTUnwrap(vaultKeys.first)
            XCTAssertEqual(vaultKey.rotationID, updatedVaultKey.rotationID)
            XCTAssertEqual(vaultKey.rotation, updatedVaultKey.rotation)
            XCTAssertEqual(vaultKey.key, updatedVaultKey.key)
            XCTAssertEqual(vaultKey.keyPassphrase, updatedVaultKey.keyPassphrase)
            XCTAssertEqual(vaultKey.keySignature, updatedVaultKey.keySignature)
            XCTAssertEqual(vaultKey.createTime, updatedVaultKey.createTime)

            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }

    func givenInsertedVaultKey(shareId: String) async throws -> VaultKey {
        let vaultKey = VaultKey.random()
        try await sut.insertVaultKeys([vaultKey], shareId: shareId)
        return vaultKey
    }

    func testCountVaultKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let givenVaultKeys = [VaultKey].random(randomElement: .random())
            let givenShareId = String.random()

            // When
            try await sut.insertVaultKeys(givenVaultKeys, shareId: givenShareId)

            // Then
            let count = try await sut.getVaultKeysCount(shareId: givenShareId)
            XCTAssertEqual(count, givenVaultKeys.count)
            expectation.fulfill()
        }
        waitForExpectations(timeout: expectationTimeOut)
    }
}
