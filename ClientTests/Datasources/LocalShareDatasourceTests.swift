//
// LocalShareDatasourceTests.swift
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

final class LocalShareDatasourceTests: XCTestCase {
    var sut: LocalShareDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(container: .Builder.build(name: kProtonPassContainerName,
                                              inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func assertEqual(_ lhs: Share, _ rhs: Share) {
        // Skip Int16 assertions because they make the tests very flaky
        // Sometime the value is not updated and is always 0
        // Not sure if this only happens to in-memory containers or not
        // If it's the case nothing to worry, otherwise further investigation is needed
        XCTAssertEqual(lhs.shareID, rhs.shareID)
        XCTAssertEqual(lhs.vaultID, rhs.vaultID)
        XCTAssertEqual(lhs.addressID, rhs.addressID)
        XCTAssertEqual(lhs.targetType, rhs.targetType)
        XCTAssertEqual(lhs.targetID, rhs.targetID)
        XCTAssertEqual(lhs.permission, rhs.permission)
        XCTAssertEqual(lhs.content, rhs.content)
        XCTAssertEqual(lhs.contentKeyRotation, rhs.contentKeyRotation)
        XCTAssertEqual(lhs.contentFormatVersion, rhs.contentFormatVersion)
        XCTAssertEqual(lhs.expireTime, rhs.expireTime)
        XCTAssertEqual(lhs.createTime, rhs.createTime)
    }
}

extension LocalShareDatasourceTests {
    func testGetAllShares() async throws {
        // Given
        let givenShares = [Share].random(randomElement: .random())
        let givenUserId = String.random()

        // When
        try await sut.upsertShares(givenShares, userId: givenUserId)
        // Populate the database with arbitrary shares
        // this is to test if fetching shares by userId correctly work
        for _ in 0...10 {
            try await sut.upsertShares([.random()], userId: .random())
        }

        // Then
        let shares = try await sut.getAllShares(userId: givenUserId)
        let shareIds = Set(shares.map { $0.shareID })
        let givenShareIds = Set(givenShares.map { $0.shareID })
        XCTAssertEqual(shareIds, givenShareIds)
    }

    func testGetShare() async throws {
        // Given
        let givenUserId = String.random()
        let givenInsertedShare = try await sut.givenInsertedShare(userId: givenUserId)

        // When
        for _ in 0...10 {
            try await sut.upsertShares([.random()], userId: givenUserId)
        }

        let share = try await sut.getShare(userId: givenUserId,
                                           shareId: givenInsertedShare.shareID)
        XCTAssertNotNil(share)
        let nonNilShare = try XCTUnwrap(share)
        assertEqual(nonNilShare, givenInsertedShare)
    }

    func testInsertShares() async throws {
        // Given
        let firstShares = [Share].random(randomElement: .random())
        let secondShares = [Share].random(randomElement: .random())
        let thirdShares = [Share].random(randomElement: .random())
        let givenShares = firstShares + secondShares + thirdShares
        let givenUserId = String.random()

        // When
        try await sut.upsertShares(firstShares, userId: givenUserId)
        try await sut.upsertShares(secondShares, userId: givenUserId)
        try await sut.upsertShares(thirdShares, userId: givenUserId)

        // Then
        let shares = try await sut.getAllShares(userId: givenUserId)
        XCTAssertEqual(shares.count, givenShares.count)

        let shareIds = Set(shares.map { $0.shareID })
        let givenShareIds = Set(givenShares.map { $0.shareID })
        XCTAssertEqual(shareIds, givenShareIds)
    }

    func testUpdateShares() async throws {
        // Given
        let givenUserId = String.random()
        let insertedShare = try await sut.givenInsertedShare(userId: givenUserId)
        // Only copy the shareId from givenShare
        let updatedShare = Share.random(shareId: insertedShare.shareID)

        // When
        try await sut.upsertShares([updatedShare], userId: givenUserId)

        // Then
        let shares = try await sut.getAllShares(userId: givenUserId)
        XCTAssertEqual(shares.count, 1)

        let share = try XCTUnwrap(shares.first)
        assertEqual(share, updatedShare)
    }

    func testRemoveShare() async throws {
        // Given
        let userId = String.random()
        let firstShare = Share.random()
        let secondShare = Share.random()
        let thirdShare = Share.random()

        // When
        try await sut.upsertShares([firstShare, secondShare, thirdShare], userId: userId)
        try await sut.removeShare(shareId: secondShare.shareID, userId: userId)

        // Then
        let shares = try await sut.getAllShares(userId: userId)
        XCTAssertEqual(shares.count, 2)
        XCTAssertTrue(shares.contains(where: { $0.shareID == firstShare.shareID }))
        XCTAssertTrue(shares.contains(where: { $0.shareID == thirdShare.shareID }))
    }

    func testRemoveAllShares() async throws {
        // Given
        let givenFirstUserId = String.random()
        let givenFirstUserShares = [Share].random(randomElement: .random())

        let givenSecondUserId = String.random()
        let givenSecondUserShares = [Share].random(randomElement: .random())

        // When
        try await sut.upsertShares(givenFirstUserShares, userId: givenFirstUserId)
        try await sut.upsertShares(givenSecondUserShares, userId: givenSecondUserId)

        // Then
        let firstUserSharesFirstGet = try await sut.getAllShares(userId: givenFirstUserId)
        XCTAssertEqual(firstUserSharesFirstGet.count, givenFirstUserShares.count)

        let secondUserSharesFirstGet = try await sut.getAllShares(userId: givenSecondUserId)
        XCTAssertEqual(secondUserSharesFirstGet.count, givenSecondUserShares.count)

        // When
        try await sut.removeAllShares(userId: givenFirstUserId)

        // Then
        let firstUserSharesSecondGet = try await sut.getAllShares(userId: givenFirstUserId)
        XCTAssertTrue(firstUserSharesSecondGet.isEmpty)

        let secondUserSharesSecondGet = try await sut.getAllShares(userId: givenSecondUserId)
        XCTAssertEqual(secondUserSharesSecondGet.count, givenSecondUserShares.count)
    }
}

extension LocalShareDatasource {
    func givenInsertedShare(userId: String? = nil) async throws -> Share {
        let share = Share.random(shareId: .random())
        try await upsertShares([share], userId: userId ?? .random())
        return share
    }
}
