//
// LocalTelemetryEventDatasourceTests.swift
// Proton Pass - Created on 24/04/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import XCTest

final class LocalTelemetryEventDatasourceTests: XCTestCase {
    var sut: LocalTelemetryEventDatasource!

    override func setUp() {
        super.setUp()
        sut = .init(databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalTelemetryEventDatasourceTests {
    func testInsertGetAndRemoveEvents() async throws {
        // Given
        let givenUserId = String.random()
        let event1 = try await givenInsertedEvent(userId: givenUserId)
        let event2 = try await givenInsertedEvent(userId: givenUserId)
        let event3 = try await givenInsertedEvent(userId: givenUserId)
        let event4 = try await givenInsertedEvent(userId: givenUserId)
        let event5 = try await givenInsertedEvent(userId: givenUserId)
        let event6 = try await givenInsertedEvent(userId: givenUserId)
        let event7 = try await givenInsertedEvent(userId: givenUserId)
        let event8 = try await givenInsertedEvent(userId: givenUserId)

        // Then
        let allEvents = try await sut.getAllEvents(userId: givenUserId)
        XCTAssertEqual(allEvents.count, 8)

        // When
        let firstThreeEvents = try await sut.getOldestEvents(count: 3, userId: givenUserId)

        // Then
        XCTAssertEqual(firstThreeEvents.count, 3)
        XCTAssertEqual(firstThreeEvents[0], event1)
        XCTAssertEqual(firstThreeEvents[1], event2)
        XCTAssertEqual(firstThreeEvents[2], event3)

        // When
        try await sut.remove(events: firstThreeEvents, userId: givenUserId)
        let secondThreeEvents = try await sut.getOldestEvents(count: 3, userId: givenUserId)

        // Then
        XCTAssertEqual(secondThreeEvents.count, 3)
        XCTAssertEqual(secondThreeEvents[0], event4)
        XCTAssertEqual(secondThreeEvents[1], event5)
        XCTAssertEqual(secondThreeEvents[2], event6)

        // When
        try await sut.remove(events: secondThreeEvents, userId: givenUserId)
        let lastEvents = try await sut.getOldestEvents(count: 3, userId: givenUserId)

        // Then
        XCTAssertEqual(lastEvents.count, 2)
        XCTAssertEqual(lastEvents[0], event7)
        XCTAssertEqual(lastEvents[1], event8)
    }

    func testRemoveAllEvents() async throws {
        // Given
        let givenUserId = String.random()
        _ = try await givenInsertedEvent(userId: givenUserId)
        _ = try await givenInsertedEvent(userId: givenUserId)
        _ = try await givenInsertedEvent(userId: givenUserId)

        // When
        try await sut.removeAllEvents(userId: givenUserId)
        let allEvents = try await sut.getAllEvents(userId: givenUserId)

        // Then
        XCTAssertEqual(allEvents.count, 0)
    }

    func givenInsertedEvent(userId: String) async throws -> TelemetryEvent {
        let event = TelemetryEvent.random()
        try await sut.insert(event: event, userId: userId)
        return event
    }
}

extension TelemetryEvent: @retroactive Equatable {
    static func random() -> TelemetryEvent {
        .init(uuid: UUID().uuidString, time: Date.now.timeIntervalSince1970, type: .random())
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.uuid == rhs.uuid && lhs.type == rhs.type
    }
}

extension TelemetryEventType {
    static func random() -> TelemetryEventType {
        let allCases: [TelemetryEventType] = [
            .create(.login), .create(.alias), .create(.note),
            .read(.login), .read(.alias), .read(.note),
            .update(.login), .update(.alias), .update(.note),
            .delete(.login), .delete(.alias), .delete(.note)
        ]
        return allCases.randomElement()! // swiftlint:disable:this force_unwrapping
    }
}
