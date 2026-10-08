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
import Testing

/// `@unchecked Sendable`: `currentDate` is only mutated by the owning test between awaited calls.
private final class MockedCurrentDateProvider: @unchecked Sendable, CurrentDateProviderProtocol {
    var currentDate = Date.now

    func getCurrentDate() -> Date { currentDate }
}

@Suite(.tags(.repository))
struct ItemReadEventRepositoryTests {
    private let localDatasource: any LocalItemReadEventDatasourceProtocol
    private let remoteDatasource = RemoteItemReadEventDatasourceProtocolMock()
    private let currentDateProvider = MockedCurrentDateProvider()
    private let sut: any ItemReadEventRepositoryProtocol

    init() {
        localDatasource = LocalItemReadEventDatasource(databaseService: DatabaseService(inMemory: true))
        sut = ItemReadEventRepository(localDatasource: localDatasource,
                                      remoteDatasource: remoteDatasource,
                                      currentDateProvider: currentDateProvider,
                                      logManager: LogManagerProtocolMock(),
                                      batchSize: 3)
    }
}

extension ItemReadEventRepositoryTests {
    @Test func `sending all events sends the oldest first in batches per share`() async throws {
        let userId = UserData.test.user.ID

        let shareId1 = String.random()
        let event1 = try await givenAddedEvent(shareId: shareId1, userId: userId, timestamp: 5)
        let event2 = try await givenAddedEvent(shareId: shareId1, userId: userId, timestamp: 1)
        let event3 = try await givenAddedEvent(shareId: shareId1, userId: userId, timestamp: 6)
        let event4 = try await givenAddedEvent(shareId: shareId1, userId: userId, timestamp: 2)

        let shareId2 = String.random()
        let event5 = try await givenAddedEvent(shareId: shareId2, userId: userId, timestamp: 10)
        let event6 = try await givenAddedEvent(shareId: shareId2, userId: userId, timestamp: 8)

        // `invokedSendParametersList` stays empty: the AutoMockable template declares it but never appends.
        var sentItemIdsByShare = [String: [[String]]]()
        remoteDatasource.closureSend = { [weak remoteDatasource] in
            guard let parameters = remoteDatasource?.invokedSendParameters else { return }
            sentItemIdsByShare[parameters.shareId, default: []].append(parameters.events.map(\.itemId))
        }

        try await sut.sendAllEvents(userId: userId)
        #expect(remoteDatasource.invokedSendCount == 3)
        #expect(sentItemIdsByShare == [
            shareId1: [[event2, event4, event1].map(\.itemId), [event3.itemId]],
            shareId2: [[event6, event5].map(\.itemId)]
        ])

        let allEvents = try await localDatasource.getAllEvents(userId: userId)
        #expect(allEvents.isEmpty)
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
