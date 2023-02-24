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
        sut = .init(container: .Builder.build(name: kProtonPassContainerName,
                                              inMemory: true))
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
        let givenKeys = [PassKey].random(randomElement: .random())

        // When
        try await sut.upsertKeys(givenKeys, shareId: givenShareId)

        // Then
        let keys = try await sut.getKeys(shareId: givenShareId)
        XCTAssertEqual(keys.count, givenKeys.count)
        XCTAssertEqual(Set(keys), Set(givenKeys))
    }

    func testInsertKeys() async throws {
        // Given
        let firstKeys = [PassKey].random(randomElement: .random())
        let secondKeys = [PassKey].random(randomElement: .random())
        let thirdKeys = [PassKey].random(randomElement: .random())
        let givenKeys = firstKeys + secondKeys + thirdKeys
        let givenShareId = String.random()

        // When
        try await sut.upsertKeys(firstKeys, shareId: givenShareId)
        try await sut.upsertKeys(secondKeys, shareId: givenShareId)
        try await sut.upsertKeys(thirdKeys, shareId: givenShareId)

        // Then
        let keys = try await sut.getKeys(shareId: givenShareId)
        XCTAssertEqual(keys.count, givenKeys.count)
        XCTAssertEqual(Set(keys), Set(givenKeys))
    }

    func testRemoveAllKeys() async throws {
        // Given
        let givenFirstShareId = String.random()
        let givenFirstShareKeys = [PassKey].random(randomElement: .random())

        let givenSecondShareId = String.random()
        let givenSecondShareKeys = [PassKey].random(randomElement: .random())

        // When
        try await sut.upsertKeys(givenFirstShareKeys, shareId: givenFirstShareId)
        try await sut.upsertKeys(givenSecondShareKeys, shareId: givenSecondShareId)

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
}

extension LocalShareKeyDatasource {
    func givenInsertedKey(shareId: String?, keyRotation: Int64?) async throws -> PassKey {
        let key = PassKey.random(keyRotation: keyRotation)
        try await upsertKeys([key], shareId: shareId ?? .random())
        return key
    }
}
