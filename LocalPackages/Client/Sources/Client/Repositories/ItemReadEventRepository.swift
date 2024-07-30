//
// ItemReadEventRepository.swift
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

import Core
import Entities
import Foundation

// sourcery: AutoMockable
public protocol ItemReadEventRepositoryProtocol: Sendable {
    func addEvent(userId: String, item: any ItemIdentifiable) async throws
    func getAllEvents(userId: String) async throws -> [ItemReadEvent]
    func sendAllEvents(userId: String) async throws
}

public actor ItemReadEventRepository: ItemReadEventRepositoryProtocol {
    private let localDatasource: any LocalItemReadEventDatasourceProtocol
    private let remoteDatasource: any RemoteItemReadEventDatasourceProtocol
    private let currentDateProvider: any CurrentDateProviderProtocol
    private let batchSize: Int
    private let logger: Logger

    public init(localDatasource: any LocalItemReadEventDatasourceProtocol,
                remoteDatasource: any RemoteItemReadEventDatasourceProtocol,
                currentDateProvider: any CurrentDateProviderProtocol,
                logManager: any LogManagerProtocol,
                batchSize: Int = Constants.Utils.batchSize) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.currentDateProvider = currentDateProvider
        logger = .init(manager: logManager)
        self.batchSize = batchSize
    }
}

public extension ItemReadEventRepository {
    func addEvent(userId: String, item: any ItemIdentifiable) async throws {
        let date = currentDateProvider.getCurrentDate()
        let event = ItemReadEvent(uuid: UUID().uuidString,
                                  shareId: item.shareId,
                                  itemId: item.itemId,
                                  timestamp: date.timeIntervalSince1970)
        try await localDatasource.insertEvent(event, userId: userId)
        logger.trace("Added event for item \(item.debugDescription), user \(userId)")
    }

    func getAllEvents(userId: String) async throws -> [ItemReadEvent] {
        try await localDatasource.getAllEvents(userId: userId)
    }

    func sendAllEvents(userId: String) async throws {
        logger.info("Sending all item reads event")
        while true {
            let events =
                try await localDatasource.getOldestEvents(count: batchSize,
                                                          userId: userId)

            if events.isEmpty {
                break
            }

            logger.trace("Found \(events.count) events for user \(userId)")

            let shouldInclude: @Sendable (ItemReadEvent) -> Bool = { _ in
                true
            }
            let action: @Sendable ([ItemReadEvent], String) async throws -> Void = { [weak self] events, shareId in
                guard let self else { return }
                try await remoteDatasource.send(userId: userId, events: events, shareId: shareId)
                try await localDatasource.removeEvents(events)
                logger.trace("Sent \(events.count) events for user \(userId)")
            }
            try await events.groupAndBulkAction(by: \.shareId,
                                                shouldInclude: shouldInclude,
                                                action: action)
        }
        logger.info("Sent all read events for user \(userId)")
    }
}
