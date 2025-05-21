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
    private let accessRepository: any AccessRepositoryProtocol

    public init(localUserEventIdDatasource: any LocalUserEventIdDatasourceProtocol,
                remoteUserEventsDatasource: any RemoteUserEventsDatasourceProtocol,
                itemRepository: any ItemRepositoryProtocol,
                accessRepository: any AccessRepositoryProtocol) {
        self.localUserEventIdDatasource = localUserEventIdDatasource
        self.remoteUserEventsDatasource = remoteUserEventsDatasource
        self.itemRepository = itemRepository
        self.accessRepository = accessRepository
    }
}

public extension UserEventsSynchronizer {
    func sync(userId: String) async throws -> UserEventsSyncResult {
        guard let lastEventId = try await localUserEventIdDatasource.getLastEventId(userId: userId) else {
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
        let events = try await remoteUserEventsDatasource.getUserEvents(userId: userId,
                                                                        lastEventId: lastEventId)

        try await process(events: events, for: userId)

        // Flip the value of the boolean to `true` onlt when it's currently `false`
        // because we might sync events in multiple batches
        // one batch might imply a change while others don't
        if !dataUpdated {
            dataUpdated = events.dataUpdated
        }

        if !planChanged {
            planChanged = events.planChanged
        }

        if !fullRefreshNeeded {
            fullRefreshNeeded = events.fullRefresh
        }

        if events.eventsPending {
            return try await sync(userId: userId,
                                  lastEventId: events.lastEventID,
                                  dataUpdated: &dataUpdated,
                                  planChanged: &planChanged,
                                  fullRefreshNeeded: &fullRefreshNeeded)
        }
    }

    func process(events: UserEvents, for userId: String) async throws {
        for updatedItem in events.itemsUpdated {
            try await itemRepository.refreshItem(userId: userId,
                                                 shareId: updatedItem.shareID,
                                                 itemId: updatedItem.itemID,
                                                 eventToken: updatedItem.eventToken)
        }

        if !events.itemsDeleted.isEmpty {
            try await itemRepository.delete(userId: userId, items: events.itemsDeleted)
        }
    }
}
