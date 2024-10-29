//
// ItemReadEventRepositoryTests.swift
// Proton Pass - Created on 11/06/2024.
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
import ClientMocks
import Core
import CoreMocks
import Entities
import Foundation
import ProtonCoreLogin
import XCTest

private final class MockedCurrentDateProvider: @unchecked Sendable, CurrentDateProviderProtocol {
    var currentDate = Date.now

    func getCurrentDate() -> Date { currentDate }
}

private final class ItemReadEventRepositoryTests: XCTestCase {
    var localDatasource: LocalItemReadEventDatasourceProtocol!
    var remoteDatasource: RemoteItemReadEventDatasourceProtocolMock!
    var userManager: UserManagerProtocolMock!
    var currentDateProvider: MockedCurrentDateProvider!
    var sut: ItemReadEventRepositoryProtocol!

    override func setUp() {
        super.setUp()
        userManager = .init()
        userManager.stubbedGetActiveUserDataResult = UserData.preview
        currentDateProvider = .init()
        localDatasource = LocalItemReadEventDatasource(databaseService: DatabaseService(inMemory: true))
        remoteDatasource = .init()
        sut = ItemReadEventRepository(localDatasource: localDatasource,
                                      remoteDatasource: remoteDatasource,
                                      currentDateProvider: currentDateProvider,
                                      logManager: LogManagerProtocolMock(),
                                      batchSize: 3)
    }

    override func tearDown() {
        localDatasource = nil
        remoteDatasource = nil
        userManager = nil
        currentDateProvider = nil
        sut = nil
        super.tearDown()
    }
}

extension ItemReadEventRepositoryTests {
    func testAddEvents() async throws {
        let userData = UserData.test
        userManager.stubbedGetActiveUserDataResult = userData
        let userId = userData.user.ID

        let shareId1 = String.random()
        let event1 = try await givenAddedEvent(shareId: shareId1, userId: userId, timestamp: 5)
        let event2 = try await givenAddedEvent(shareId: shareId1, userId: userId, timestamp: 1)
        let event3 = try await givenAddedEvent(shareId: shareId1, userId: userId, timestamp: 6)
        let event4 = try await givenAddedEvent(shareId: shareId1, userId: userId, timestamp: 2)

        let expectation1 = expectation(description: "First batch for shareId1")
        let expectation2 = expectation(description: "Second batch for shareId1")

        let shareId2 = String.random()
        let event5 = try await givenAddedEvent(shareId: shareId2, userId: userId, timestamp: 10)
        let event6 = try await givenAddedEvent(shareId: shareId2, userId: userId, timestamp: 8)

        let expectation3 = expectation(description: "Only batch for shareId2")

        remoteDatasource.closureSend = {
            let (_, events, shareId) = self.remoteDatasource.invokedSendParameters!
            switch shareId {
            case shareId1:
                if events.map(\.itemId) == [event2, event4, event1].map(\.itemId) {
                    expectation1.fulfill()
                }

                if events.map(\.itemId) == [event3].map(\.itemId) {
                    expectation2.fulfill()
                }

            case shareId2:
                if events.map(\.itemId) == [event6, event5].map(\.itemId) {
                    expectation3.fulfill()
                }

            default:
                XCTFail("Unknown shareId")
            }
        }

        try await sut.sendAllEvents(userId: userId)
        XCTAssertEqual(remoteDatasource.invokedSendCount, 3)

        let allEvents = try await localDatasource.getAllEvents(userId: userId)
        XCTAssertTrue(allEvents.isEmpty)

        await fulfillment(of: [expectation1, expectation2, expectation3], timeout: 1)
    }
}

private extension ItemReadEventRepositoryTests {
    func givenAddedEvent(shareId: String,
                         userId: String,
                         timestamp: TimeInterval) async throws -> ItemReadEvent {
        currentDateProvider.currentDate = Date(timeIntervalSince1970: timestamp)
        let item = ItemMock(shareId: shareId, itemId: .random())
        try await sut.addEvent(userId: userId, item: item)
        return .init(uuid: .random(),
                     shareId: shareId,
                     itemId: item.itemId,
                     timestamp: timestamp)
    }
}
