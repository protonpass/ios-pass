//
// UserEventsSynchronizer.swift
// Proton Pass - Created on 16/05/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Core
import Foundation

/// The result of user events sync giving information to act upon on
public struct UserEventsSyncResult: Sendable, Equatable {
    /// Items or shares were updated, a UI refresh is needed to reflect updated data
    public let dataUpdated: Bool

    /// User's plan has changed (e.g free -> paid), go fetch the updated plan
    public let planChanged: Bool

    /// Force full sync (e.g users haven't used the app for a long period and last event ID is obsolete)
    public let fullRefreshNeeded: Bool

    public init(dataUpdated: Bool,
                planChanged: Bool,
                fullRefreshNeeded: Bool) {
        self.dataUpdated = dataUpdated
        self.planChanged = planChanged
        self.fullRefreshNeeded = fullRefreshNeeded
    }
}

public protocol UserEventsSynchronizerProtocol: Sendable {
    func sync(userId: String) async throws -> UserEventsSyncResult
}

public actor UserEventsSynchronizer: UserEventsSynchronizerProtocol {
    private let localUserEventIdDatasource: any LocalUserEventIdDatasourceProtocol
    private let remoteUserEventsDatasource: any RemoteUserEventsDatasourceProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let accessRepository: any AccessRepositoryProtocol
    private let logger: Logger

    public init(localUserEventIdDatasource: any LocalUserEventIdDatasourceProtocol,
                remoteUserEventsDatasource: any RemoteUserEventsDatasourceProtocol,
                itemRepository: any ItemRepositoryProtocol,
                shareRepository: any ShareRepositoryProtocol,
                accessRepository: any AccessRepositoryProtocol,
                logManager: any LogManagerProtocol) {
        self.localUserEventIdDatasource = localUserEventIdDatasource
        self.remoteUserEventsDatasource = remoteUserEventsDatasource
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.accessRepository = accessRepository
        logger = .init(manager: logManager)
    }
}

public extension UserEventsSynchronizer {
    func sync(userId: String) async throws -> UserEventsSyncResult {
        logger.trace("Syncing with user events for user \(userId)")
        guard let lastEventId = try await localUserEventIdDatasource.getLastEventId(userId: userId) else {
            logger.warning("No local user event ID for user \(userId). Force full refresh.")
            return .init(dataUpdated: false, planChanged: false, fullRefreshNeeded: true)
        }
        var dataUpdated = false
        var planChanged = false
        var fullRefreshNeeded = false
        try await sync(userId: userId,
                       lastEventId: lastEventId,
                       dataUpdated: &dataUpdated,
                       planChanged: &planChanged,
                       fullRefreshNeeded: &fullRefreshNeeded)
        logger.info("Finished syncing with user events for user \(userId)")
        return .init(dataUpdated: dataUpdated,
                     planChanged: planChanged,
                     fullRefreshNeeded: fullRefreshNeeded)
    }
}

private extension UserEventsSynchronizer {
    func sync(userId: String,
              lastEventId: String,
              dataUpdated: inout Bool,
              planChanged: inout Bool,
              fullRefreshNeeded: inout Bool) async throws {
        logger.trace("Getting user events for user \(userId)")
        let events = try await remoteUserEventsDatasource.getUserEvents(userId: userId,
                                                                        lastEventId: lastEventId)
        logger.trace("Processing events for user \(userId)")
        try await process(events: events, for: userId)
        logger.trace("Processed events for user \(userId)")

        dataUpdated = dataUpdated || events.dataUpdated
        planChanged = planChanged || events.planChanged
        fullRefreshNeeded = fullRefreshNeeded || events.fullRefresh

        logger.trace("Upserting last user event ID for user \(userId)")
        try await localUserEventIdDatasource.upsertLastEventId(userId: userId,
                                                               lastEventId: events.lastEventID)

        if events.eventsPending {
            logger.trace("Continue syncing because events are still pending for user \(userId)")
            return try await sync(userId: userId,
                                  lastEventId: events.lastEventID,
                                  dataUpdated: &dataUpdated,
                                  planChanged: &planChanged,
                                  fullRefreshNeeded: &fullRefreshNeeded)
        }
    }

    func process(events: UserEvents, for userId: String) async throws {
        if events.itemsUpdated.isEmpty {
            logger.trace("No updated items for user \(userId)")
        } else {
            logger.trace("Refreshing \(events.itemsUpdated.count) updated items for user \(userId)")
            for updatedItem in events.itemsUpdated {
                try await itemRepository.refreshItem(userId: userId,
                                                     shareId: updatedItem.shareID,
                                                     itemId: updatedItem.itemID,
                                                     eventToken: updatedItem.eventToken)
            }
        }

        if events.itemsDeleted.isEmpty {
            logger.trace("No deleted items for user \(userId)")
        } else {
            logger.trace("Deleting \(events.itemsDeleted.count) items for user \(userId)")
            try await itemRepository.delete(userId: userId, items: events.itemsDeleted)
        }

        if events.sharesUpdated.isEmpty {
            logger.trace("No updated shares for user \(userId)")
        } else {
            logger.trace("Refreshing \(events.sharesUpdated.count) shares for user \(userId)")
            for updatedShare in events.sharesUpdated {
                try await shareRepository.refreshShare(userId: userId,
                                                       shareId: updatedShare.shareID,
                                                       eventToken: updatedShare.eventToken)
            }
        }

        if events.sharesDeleted.isEmpty {
            logger.trace("No deleted shares for user \(userId)")
        } else {
            logger.trace("Deleting \(events.sharesDeleted.count) shares for user \(userId)")
            for deletedShare in events.sharesDeleted {
                try await shareRepository.deleteShareLocally(userId: userId,
                                                             shareId: deletedShare.shareID)
                try await itemRepository.deleteAllItemsLocally(shareId: deletedShare.shareID)
            }
        }
    }
}
