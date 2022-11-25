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
    func testGetItemKeys() async throws {
        // Given
        let localShareDatasource = LocalShareDatasource(container: sut.container)
        let givenShare = try await localShareDatasource.givenInsertedShare()
        let givenShareId = givenShare.shareID
        let givenItemKeys = [ItemKey].random(randomElement: .random())

        // When
        try await sut.upsertItemKeys(givenItemKeys, shareId: givenShareId)

        // Then
        let itemKeys = try await sut.getItemKeys(shareId: givenShareId)
        XCTAssertEqual(Set(itemKeys), Set(givenItemKeys))
    }

    func testInsertItemKeys() async throws {
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
        let itemKeys = try await sut.getItemKeys(shareId: givenShareId)
        XCTAssertEqual(Set(itemKeys), Set(givenItemKeys))
    }

    func testUpdateItemKeys() async throws {
        // Given
        let givenShareId = String.random()
        let givenItemKeys = [ItemKey].random(randomElement: .random())
        try await sut.upsertItemKeys(givenItemKeys, shareId: givenShareId)
        let firstInsertedItemKey = try XCTUnwrap(givenItemKeys.first)
        let updatedFirstItemKey = ItemKey.random(rotationId: firstInsertedItemKey.rotationID)

        // When
        try await sut.upsertItemKeys([updatedFirstItemKey], shareId: givenShareId)

        // Then
        let itemKeys = try await sut.getItemKeys(shareId: givenShareId)
        XCTAssertEqual(itemKeys.count, givenItemKeys.count)
        let firstItemKey =
        try XCTUnwrap(itemKeys.first(where: { $0.rotationID == firstInsertedItemKey.rotationID }))
        assertEqual(firstItemKey, updatedFirstItemKey)
    }

    func testRemoveAllItemKeys() async throws {
        // Given
        let givenFirstShareId = String.random()
        let givenFirstShareItemKeys = [ItemKey].random(randomElement: .random())

        let givenSecondShareId = String.random()
        let givenSecondShareItemKeys = [ItemKey].random(randomElement: .random())

        // When
        try await sut.upsertItemKeys(givenFirstShareItemKeys, shareId: givenFirstShareId)
        try await sut.upsertItemKeys(givenSecondShareItemKeys, shareId: givenSecondShareId)

        // Then
        let firstShareItemKeysFirstGet = try await sut.getItemKeys(shareId: givenFirstShareId)
        XCTAssertEqual(Set(givenFirstShareItemKeys), Set(firstShareItemKeysFirstGet))

        let secondShareItemKeysFirstGet = try await sut.getItemKeys(shareId: givenSecondShareId)
        XCTAssertEqual(Set(secondShareItemKeysFirstGet), Set(givenSecondShareItemKeys))

        // When
        try await sut.removeAllItemKeys(shareId: givenFirstShareId)

        // Then
        let firstShareItemKeysSecondGet = try await sut.getItemKeys(shareId: givenFirstShareId)
        XCTAssertTrue(firstShareItemKeysSecondGet.isEmpty)

        let secondShareItemKeysSecondGet = try await sut.getItemKeys(shareId: givenSecondShareId)
        XCTAssertEqual(Set(secondShareItemKeysSecondGet), Set(givenSecondShareItemKeys))
    }
}

extension LocalItemKeyDatasource {
    func givenInsertedItemKey(shareId: String?, rotationId: String?) async throws -> ItemKey {
        let itemKey = ItemKey.random(rotationId: rotationId)
        try await upsertItemKeys([itemKey], shareId: shareId ?? .random())
        return itemKey
    }
}
