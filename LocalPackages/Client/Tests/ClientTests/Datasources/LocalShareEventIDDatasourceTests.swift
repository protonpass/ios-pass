//
// LocalShareEventIDDatasourceTests.swift
// Proton Pass - Created on 27/10/2022.
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

final class LocalShareEventIDDatasourceTests: XCTestCase {
    var sut: LocalShareEventIDDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalShareEventIDDatasourceTests {
    func testUpsertLastEventId() async throws {
        // Given
        let userId = String.random()
        let shareId = String.random()

        // When
        let eventId0 = try await sut.getLastEventId(userId: userId, shareId: shareId)

        // Then
        XCTAssertNil(eventId0)

        // Given
        let givenEventId1 = String.random()

        // When
        try await sut.upsertLastEventId(userId: userId,
                                        shareId: shareId,
                                        lastEventId: givenEventId1)

        // Then
        let eventId1 = try await XCTUnwrapAsync(await sut.getLastEventId(userId: userId,
                                                                         shareId: shareId))
        XCTAssertEqual(eventId1, givenEventId1)

        // Given
        let givenEventId2 = String.random()

        // When
        try await sut.upsertLastEventId(userId: userId,
                                        shareId: shareId,
                                        lastEventId: givenEventId2)

        // Then
        let eventId2 = try await XCTUnwrapAsync(await sut.getLastEventId(userId: userId,
                                                                         shareId: shareId))
        XCTAssertEqual(eventId2, givenEventId2)
    }

    func testRemoveAllEntries() async throws {
        // Given
        let userId1 = String.random()
        let shareId1 = String.random()
        try await sut.upsertLastEventId(userId: userId1,
                                        shareId: shareId1,
                                        lastEventId: .random())
        let shareId2 = String.random()
        try await sut.upsertLastEventId(userId: userId1,
                                        shareId: shareId2,
                                        lastEventId: .random())

        let userId2 = String.random()
        let shareId3 = String.random()
        try await sut.upsertLastEventId(userId: userId2,
                                        shareId: shareId3,
                                        lastEventId: .random())

        let shareId4 = String.random()
        try await sut.upsertLastEventId(userId: userId2,
                                        shareId: shareId4,
                                        lastEventId: .random())

        // When
        try await sut.removeAllEntries(userId: userId1)

        // Then
        let eventId1 = try await sut.getLastEventId(userId: userId1, shareId: shareId1)
        XCTAssertNil(eventId1)

        let eventId2 = try await sut.getLastEventId(userId: userId1, shareId: shareId2)
        XCTAssertNil(eventId2)

        let eventId3 = try await sut.getLastEventId(userId: userId2, shareId: shareId3)
        XCTAssertNotNil(eventId3)

        let eventId4 = try await sut.getLastEventId(userId: userId2, shareId: shareId4)
        XCTAssertNotNil(eventId4)
    }
}
