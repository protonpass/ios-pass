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
        sut = .init(databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalShareDatasourceTests {
    func testGetAllShares() async throws {
        // Given
        let givenShares = [SymmetricallyEncryptedShare].random(randomElement: .random())
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
        let shareIds = Set(shares.map(\.share.shareID))
        let givenShareIds = Set(givenShares.map(\.share.shareID))
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

        let optionalShares = try await sut.getShare(userId: givenUserId,
                                                    shareId: givenInsertedShare.share.shareID)
        let share = try await XCTUnwrapAsync(optionalShares)
        XCTAssertEqual(share, givenInsertedShare)
    }

    func testInsertShares() async throws {
        // Given
        let firstShares = [SymmetricallyEncryptedShare].random(randomElement: .random())
        let secondShares = [SymmetricallyEncryptedShare].random(randomElement: .random())
        let thirdShares = [SymmetricallyEncryptedShare].random(randomElement: .random())
        let givenShares = firstShares + secondShares + thirdShares
        let givenUserId = String.random()

        // When
        try await sut.upsertShares(firstShares, userId: givenUserId)
        try await sut.upsertShares(secondShares, userId: givenUserId)
        try await sut.upsertShares(thirdShares, userId: givenUserId)

        // Then
        let shares = try await sut.getAllShares(userId: givenUserId)
        XCTAssertEqual(shares.count, givenShares.count)

        let shareIds = Set(shares.map(\.share.shareID))
        let givenShareIds = Set(givenShares.map(\.share.shareID))
        XCTAssertEqual(shareIds, givenShareIds)
    }

    func testUpdateShares() async throws {
        // Given
        let givenUserId = String.random()
        let insertedShare = try await sut.givenInsertedShare(userId: givenUserId)
        // Only copy the shareId from givenShare
        let updatedShare = SymmetricallyEncryptedShare(encryptedContent: .random(),
                                                       share: .random(shareId: insertedShare.share.shareID))

        // When
        try await sut.upsertShares([updatedShare], userId: givenUserId)

        // Then
        let shares = try await sut.getAllShares(userId: givenUserId)
        XCTAssertEqual(shares.count, 1)

        let share = try XCTUnwrap(shares.first)
        XCTAssertEqual(share, updatedShare)
    }

    func testRemoveShare() async throws {
        // Given
        let userId = String.random()
        let firstShare = SymmetricallyEncryptedShare.random()
        let secondShare = SymmetricallyEncryptedShare.random()
        let thirdShare = SymmetricallyEncryptedShare.random()

        // When
        try await sut.upsertShares([firstShare, secondShare, thirdShare], userId: userId)
        try await sut.removeShare(shareId: secondShare.share.shareID, userId: userId)

        // Then
        let shares = try await sut.getAllShares(userId: userId)
        XCTAssertEqual(shares.count, 2)
        XCTAssertTrue(shares.contains(where: { $0.share.shareID == firstShare.share.shareID }))
        XCTAssertTrue(shares.contains(where: { $0.share.shareID == thirdShare.share.shareID }))
    }

    func testRemoveAllShares() async throws {
        // Given
        let givenFirstUserId = String.random()
        let givenFirstUserShares = [SymmetricallyEncryptedShare].random(randomElement: .random())

        let givenSecondUserId = String.random()
        let givenSecondUserShares = [SymmetricallyEncryptedShare].random(randomElement: .random())

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
    func givenInsertedShare(userId: String? = nil) async throws -> SymmetricallyEncryptedShare {
        let share = SymmetricallyEncryptedShare.random()
        try await upsertShares([share], userId: userId ?? .random())
        return share
    }
}
