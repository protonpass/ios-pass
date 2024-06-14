//
// LocalItemReadEventDatasourceTests.swift
// Proton Pass - Created on 10/06/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

@testable import Client
import Core
import Entities
import Foundation
import XCTest

private final class LocalItemReadEventDatasourceTests: XCTestCase {
    var sut: (any LocalItemReadEventDatasourceProtocol)!

    override func setUp() {
        super.setUp()
        sut = LocalItemReadEventDatasource(databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalItemReadEventDatasourceTests {
    func testInsertGetRemoveEvents() async throws {
        let userId1 = String.random()
        let event1 = try await givenInsertedEvent(userId: userId1,
                                                  timestamp: 4)
        let event2 = try await givenInsertedEvent(userId: userId1,
                                                  timestamp: 2)
        let event3 = try await givenInsertedEvent(userId: userId1,
                                                  timestamp: 6)
        let event4 = try await givenInsertedEvent(userId: userId1,
                                                  timestamp: 8)
        let event5 = try await givenInsertedEvent(userId: userId1,
                                                  timestamp: 1)

        let batch1 = try await sut.getOldestEvents(count: 3, userId: userId1)
        XCTAssertEqual(batch1, [event5, event2, event1])

        let batch2 = try await sut.getAllEvents(userId: userId1)
        XCTAssertEqual(batch2, [event5, event2, event1, event3, event4])

        try await sut.removeEvents(batch1)

        let userId2 = String.random()
        let event6 = try await givenInsertedEvent(userId: userId2,
                                                  timestamp: 7)
        let event7 = try await givenInsertedEvent(userId: userId2,
                                                  timestamp: 3)
        let event8 = try await givenInsertedEvent(userId: userId2,
                                                  timestamp: 9)

        let batch3 = try await sut.getOldestEvents(count: 3, userId: userId1)
        XCTAssertEqual(batch3, [event3, event4])

        let batch4 = try await sut.getOldestEvents(count: 2, userId: userId2)
        XCTAssertEqual(batch4, [event7, event6])

        let batch5 = try await sut.getAllEvents(userId: userId2)
        XCTAssertEqual(batch5, [event7, event6, event8])
    }
}

private extension LocalItemReadEventDatasourceTests {
    func givenInsertedEvent(userId: String,
                            timestamp: TimeInterval) async throws -> ItemReadEvent {
        let event = ItemReadEvent(uuid: .random(),
                                  shareId: .random(),
                                  itemId: .random(),
                                  timestamp: timestamp)
        try await sut.insertEvent(event, userId: userId)
        return event
    }
}
