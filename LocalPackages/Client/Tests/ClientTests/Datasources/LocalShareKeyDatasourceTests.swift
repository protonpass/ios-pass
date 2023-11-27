//
// LocalShareKeyDatasourceTests.swift
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

final class LocalShareKeyDatasourceTests: XCTestCase {
    var sut: LocalShareKeyDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalShareKeyDatasourceTests {
    func testGetKeys() async throws {
        // Given
        let givenShareId = String.random()
        let givenKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenShareId,
                                         shareKey: .random()))

        // When
        try await sut.upsertKeys(givenKeys)

        // Then
        let keys = try await sut.getKeys(shareId: givenShareId)
        XCTAssertEqual(keys.count, givenKeys.count)
        XCTAssertEqual(Set(keys), Set(givenKeys))
    }

    func testInsertKeys() async throws {
        // Given
        let givenShareId = String.random()
        let firstKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenShareId,
                                         shareKey: .random()))
        let secondKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenShareId,
                                         shareKey: .random()))
        let thirdKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenShareId,
                                         shareKey: .random()))
        let givenKeys = firstKeys + secondKeys + thirdKeys

        // When
        try await sut.upsertKeys(firstKeys)
        try await sut.upsertKeys(secondKeys)
        try await sut.upsertKeys(thirdKeys)

        // Then
        let keys = try await sut.getKeys(shareId: givenShareId)
        XCTAssertEqual(keys.count, givenKeys.count)
        XCTAssertEqual(Set(keys), Set(givenKeys))
    }

    func testRemoveAllKeysForGivenShares() async throws {
        // Given
        let givenFirstShareId = String.random()
        let givenFirstShareKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenFirstShareId,
                                         shareKey: .random()))

        let givenSecondShareId = String.random()
        let givenSecondShareKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenSecondShareId,
                                         shareKey: .random()))

        // When
        try await sut.upsertKeys(givenFirstShareKeys)
        try await sut.upsertKeys(givenSecondShareKeys)

        // Then
        let firstShareKeysFirstGet = try await sut.getKeys(shareId: givenFirstShareId)
        XCTAssertEqual(Set(givenFirstShareKeys), Set(firstShareKeysFirstGet))

        let secondShareKeysFirstGet = try await sut.getKeys(shareId: givenSecondShareId)
        XCTAssertEqual(Set(secondShareKeysFirstGet), Set(givenSecondShareKeys))

        // When
        try await sut.removeAllKeys(shareId: givenFirstShareId)

        // Then
        let firstShareKeysSecondGet = try await sut.getKeys(shareId: givenFirstShareId)
        XCTAssertTrue(firstShareKeysSecondGet.isEmpty)

        let secondShareKeysSecondGet = try await sut.getKeys(shareId: givenSecondShareId)
        XCTAssertEqual(Set(secondShareKeysSecondGet), Set(givenSecondShareKeys))
    }

    func testRemoveAllKeys() async throws {
        // Given
        let givenFirstShareId = String.random()
        let givenFirstShareKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenFirstShareId,
                                         shareKey: .random()))

        let givenSecondShareId = String.random()
        let givenSecondShareKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenSecondShareId,
                                         shareKey: .random()))

        // When
        try await sut.upsertKeys(givenFirstShareKeys)
        try await sut.upsertKeys(givenSecondShareKeys)

        // Then
        let firstShareKeysFirstGet = try await sut.getKeys(shareId: givenFirstShareId)
        XCTAssertEqual(Set(givenFirstShareKeys), Set(firstShareKeysFirstGet))

        let secondShareKeysFirstGet = try await sut.getKeys(shareId: givenSecondShareId)
        XCTAssertEqual(Set(secondShareKeysFirstGet), Set(givenSecondShareKeys))

        // When
        try await sut.removeAllKeys()

        // Then
        let firstShareKeysSecondGet = try await sut.getKeys(shareId: givenFirstShareId)
        XCTAssertTrue(firstShareKeysSecondGet.isEmpty)

        let secondShareKeysSecondGet = try await sut.getKeys(shareId: givenSecondShareId)
        XCTAssertTrue(secondShareKeysSecondGet.isEmpty)
    }
}
