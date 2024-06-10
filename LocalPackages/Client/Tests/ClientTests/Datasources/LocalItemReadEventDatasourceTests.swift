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

private final class MockedCurrentDateProvider: CurrentDateProviderProtocol {
    var currentDate = Date.now

    func getCurrentDate() -> Date { currentDate }
}

private final class LocalItemReadEventDatasourceTests: XCTestCase {
    var currentDateProvider: MockedCurrentDateProvider!
    var sut: (any LocalItemReadEventDatasourceProtocol)!

    override func setUp() {
        super.setUp()
        currentDateProvider = .init()
        sut = LocalItemReadEventDatasource(
            currentDateProvider: currentDateProvider,
            databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        currentDateProvider = nil
        sut = nil
        super.tearDown()
    }
}

extension LocalItemReadEventDatasourceTests {
    func testInsertGetRemoveEvents() async throws {
        let userId1 = String.random()
        let event1 = try await insertRandomEvent(timestamp: 17,
                                                 userId: userId1)
        let event2 = try await insertRandomEvent(timestamp: 20,
                                                 userId: userId1)
        let event3 = try await insertRandomEvent(timestamp: 34,
                                                 userId: userId1)
        let event4 = try await insertRandomEvent(timestamp: 4,
                                                 userId: userId1)

        let userId2 = String.random()
        let event5 = try await insertRandomEvent(timestamp: 10,
                                                 userId: userId2)

        let eventsForUserId1FirstGet = try await sut.getAllEvents(userId: userId1)
        XCTAssertEqual(eventsForUserId1FirstGet, [event4, event1, event2, event3])

        try await sut.removeAllEvents(userId: userId1)
        let eventsForUserId1SecondGet = try await sut.getAllEvents(userId: userId1)
        XCTAssertTrue(eventsForUserId1SecondGet.isEmpty)

        let eventsForUserId2FirstGet = try await sut.getAllEvents(userId: userId2)
        XCTAssertEqual(eventsForUserId2FirstGet, [event5])

        try await sut.removeAllEvents(userId: userId2)
        let eventsForUserId2SecondGet = try await sut.getAllEvents(userId: userId1)
        XCTAssertTrue(eventsForUserId2SecondGet.isEmpty)
    }
}

private extension LocalItemReadEventDatasourceTests {
    func insertRandomEvent(timestamp: Double,
                           userId: String) async throws -> ItemReadEvent {
        currentDateProvider.currentDate = Date(timeIntervalSince1970: timestamp)
        let item = MockedItemIdentiable.random()
        try await sut.insertEvent(item, userId: userId)
        return .init(shareId: item.shareId,
                     itemId: item.itemId,
                     timestamp: timestamp)
    }
}
