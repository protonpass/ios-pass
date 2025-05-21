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
        let events = try await remoteUserEventsDatasource.getUserEvents(userId: userId,
                                                                        lastEventId: lastEventId)
        try await process(events: events, userId: userId)
        if events.eventsPending {
            return try await sync(userId: userId)
        }
        return .init(dataUpdated: false, planChanged: false, fullRefreshNeeded: false)
    }
}

private extension UserEventsSynchronizer {
    func process(events: UserEvents, userId: String) async throws {
        for updatedItem in events.itemsUpdated {
            try await itemRepository.refreshItem(userId: userId,
                                                 shareId: updatedItem.shareID,
                                                 itemId: updatedItem.itemID,
                                                 eventToken: updatedItem.eventToken)
        }

        try await itemRepository.delete(userId: userId, items: events.itemsDeleted)
    }
}

// public let lastEventID: String
// public let itemsUpdated: [UserEventItem]
// public let itemsDeleted: [UserEventItem]
// public let sharesUpdated: [UserEventShare]
// public let sharesDeleted: [UserEventShare]
// public let sharesToGetInvites: [UserEventShare]
// public let sharesWithInvitesToCreate: [UserEventShare]
// public let planChanged: Bool
// public let eventsPending: Bool
// public let fullRefresh: Bool
