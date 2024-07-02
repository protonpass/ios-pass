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
import Entities
import TestingToolkit
import XCTest

final class LocalShareKeyDatasourceTests: XCTestCase {
    var sut: LocalShareKeyDatasourceProtocol!

    override func setUp() {
        super.setUp()
        sut = LocalShareKeyDatasource(databaseService: DatabaseService(inMemory: true))
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
        let givenUserId = String.random()
        let givenKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenShareId,
                                         userId: givenUserId,
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
        let givenUserId = String.random()
        let firstKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenShareId,
                                         userId: givenUserId,
                                         shareKey: .random()))
        let secondKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenShareId,
                                         userId: givenUserId,
                                         shareKey: .random()))
        let thirdKeys = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: givenShareId,
                                         userId: givenUserId,
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

    func testRemoveAllKeys() async throws {
        // Given
        let userId1 = String.random()
        let shareId1 = String.random()
        let shares1 = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: shareId1,
                                         userId: userId1,
                                         shareKey: .random()))

        let userId2 = String.random()
        let shareId2 = String.random()
        let shares2 = [SymmetricallyEncryptedShareKey]
            .random(randomElement: .init(encryptedKey: .random(),
                                         shareId: shareId2,
                                         userId: userId2,
                                         shareKey: .random()))

        // When
        try await sut.upsertKeys(shares1)
        try await sut.upsertKeys(shares2)

        // Then
        try await XCTAssertEqualAsync(Set(await sut.getKeys(shareId: shareId1)), Set(shares1))
        try await XCTAssertEqualAsync(Set(await sut.getKeys(shareId: shareId2)), Set(shares2))

        // When
        try await sut.removeAllKeys(userId: userId1)

        // Then
        try await XCTAssertEmptyAsync(await sut.getKeys(shareId: shareId1))
        try await XCTAssertEqualAsync(Set(await sut.getKeys(shareId: shareId2)), Set(shares2))
    }
}
