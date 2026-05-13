//
// CoreEventsSynchronizer.swift
// Proton Pass - Created on 12/05/2026.
// Copyright (c) 2026 Proton Technologies AG
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
import Entities

public protocol CoreEventsSynchronizerProtocol: Sendable {
    func sync(userId: String) async throws
}

public final class CoreEventsSynchronizer: CoreEventsSynchronizerProtocol {
    let localDatasource: any LocalCoreEventIdDatasourceProtocol
    let remoteDatasource: any RemoteCoreEventIdDatasourceProtocol
    let remoteUserDataSource: any RemoteUserDataDatasourceProtocol
    let userManager: any UserManagerProtocol
    let logger: Logger

    public init(localDatasource: any LocalCoreEventIdDatasourceProtocol,
                remoteDatasource: any RemoteCoreEventIdDatasourceProtocol,
                remoteUserDataSource: any RemoteUserDataDatasourceProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.remoteUserDataSource = remoteUserDataSource
        self.userManager = userManager
        logger = .init(manager: logManager)
    }

    public func sync(userId: String) async throws {
        logger.trace("Start syncing core events")
        guard let lastEventId = try await localDatasource.getLastEventId(userId: userId) else {
            logger.trace("No lastEventId found. Refreshing user data.")
            try await updateUserData(userId: userId)
            return
        }
        let events = try await remoteDatasource.getCoreEvents(userId: userId, lastEventId: lastEventId)
        if events.shouldRefreshUserData {
            logger.trace("Core events require updating user data")
            try await updateUserData(userId: userId)
        } else {
            logger.trace("Core events found but no need to update user data")
        }
        logger.trace("Finish syncing core events")
    }
}

private extension CoreEventsSynchronizer {
    func updateUserData(userId: String) async throws {
        logger.trace("Updating user data")
        guard let oldUserData = try await userManager.getUserData(userId) else {
            throw PassError.userManager(.userNotFound(userId: userId))
        }
        let updatedUserData = try await remoteUserDataSource.getUpdatedUserData(oldUserData)
        let eventId = try await remoteDatasource.getLatestCoreEventId(userId: userId)
        try await userManager.upsertAndSetUpAgain(userData: updatedUserData)
        try await localDatasource.upsertLastEventId(userId: userId, lastEventId: eventId)
        logger.trace("Updated user data")
    }
}

private extension CoreEvents {
    var shouldRefreshUserData: Bool {
        let events = (users ?? []) + (addresses ?? [])
        return events.contains(where: { $0.action == .update })
    }
}
