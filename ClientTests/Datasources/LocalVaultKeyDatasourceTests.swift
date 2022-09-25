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
    func testGetVaultKeys() throws {
        continueAfterFailure = false
        let expectation = expectation(description: #function)
        Task {
            // Given
            let localShareDatasource = LocalShareDatasource(container: sut.container)
            let givenShare = try await localShareDatasource.givenInsertedShare()
            let givenShareId = givenShare.shareID
            let givenVaultKeys = [VaultKey].random(randomElement: .random())

            // When
            try await sut.upsertVaultKeys(givenVaultKeys, shareId: givenShareId)

            // Then
            let vaultKeys = try await sut.getVaultKeys(shareId: givenShareId)
            XCTAssertEqual(Set(vaultKeys), Set(givenVaultKeys))

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
            let vaultKeys = try await sut.getVaultKeys(shareId: givenShareId)
            XCTAssertEqual(Set(vaultKeys), Set(givenVaultKeys))

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
            let givenVaultKeys = [VaultKey].random(randomElement: .random())
            try await sut.upsertVaultKeys(givenVaultKeys, shareId: givenShareId)
            let firstInsertedVaultKey = try XCTUnwrap(givenVaultKeys.first)
            let updatedFirstVaultKey = VaultKey.random(rotationId: firstInsertedVaultKey.rotationID)

            // When
            try await sut.upsertVaultKeys([updatedFirstVaultKey], shareId: givenShareId)

            // Then
            let vaultKeys = try await sut.getVaultKeys(shareId: givenShareId)
            XCTAssertEqual(vaultKeys.count, givenVaultKeys.count)
            let firstVaultKey =
            try XCTUnwrap(vaultKeys.first(where: { $0.rotationID == firstInsertedVaultKey.rotationID }))
            assertEqual(firstVaultKey, updatedFirstVaultKey)

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
            try await sut.upsertVaultKeys(givenFirstShareVaultKeys, shareId: givenFirstShareId)
            try await sut.upsertVaultKeys(givenSecondShareVaultKeys, shareId: givenSecondShareId)

            // Then
            let firstShareVaultKeysFirstGet = try await sut.getVaultKeys(shareId: givenFirstShareId)
            XCTAssertEqual(Set(givenFirstShareVaultKeys), Set(firstShareVaultKeysFirstGet))

            let secondShareVaultKeysFirstGet = try await sut.getVaultKeys(shareId: givenSecondShareId)
            XCTAssertEqual(Set(secondShareVaultKeysFirstGet), Set(givenSecondShareVaultKeys))

            // When
            try await sut.removeAllVaultKeys(shareId: givenFirstShareId)

            // Then
            let firstShareVaultKeysSecondGet = try await sut.getVaultKeys(shareId: givenFirstShareId)
            XCTAssertTrue(firstShareVaultKeysSecondGet.isEmpty)

            let secondShareVaultKeysSecondGet = try await sut.getVaultKeys(shareId: givenSecondShareId)
            XCTAssertEqual(Set(secondShareVaultKeysSecondGet), Set(givenSecondShareVaultKeys))

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
