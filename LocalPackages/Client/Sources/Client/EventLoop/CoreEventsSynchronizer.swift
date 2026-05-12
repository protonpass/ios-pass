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

import Entities

public protocol CoreEventsSynchronizerProtocol: Sendable {
    func sync(userId: String) async throws
}

public final class CoreEventsSynchronizer: CoreEventsSynchronizerProtocol {
    let localDatasource: any LocalCoreEventIdDatasourceProtocol
    let remoteDatasource: any RemoteCoreEventIdDatasourceProtocol
    let remoteUserDataSource: any RemoteUserDataDatasourceProtocol
    let userManager: any UserManagerProtocol

    public init(localDatasource: any LocalCoreEventIdDatasourceProtocol,
                remoteDatasource: any RemoteCoreEventIdDatasourceProtocol,
                remoteUserDataSource: any RemoteUserDataDatasourceProtocol,
                userManager: any UserManagerProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.remoteUserDataSource = remoteUserDataSource
        self.userManager = userManager
    }

    public func sync(userId: String) async throws {
        guard let lastEventId = try await localDatasource.getLastEventId(userId: userId) else {
            // No known lastEventId => considered outdated data
            try await updateUserData(userId: userId)
            return
        }
        let events = try await remoteDatasource.getCoreEvents(userId: userId, lastEventId: lastEventId)
        if events.shouldRefreshUserData {
            try await updateUserData(userId: userId)
        }
    }
}

private extension CoreEventsSynchronizer {
    func updateUserData(userId: String) async throws {
        guard let oldUserData = try await userManager.getUserData(userId) else {
            throw PassError.userManager(.userNotFound(userId: userId))
        }
        let updatedUserData = try await remoteUserDataSource.getUpdatedUserData(oldUserData)
        let eventId = try await remoteDatasource.getLatestCoreEventId(userId: userId)
        try await userManager.upsertAndSetUpAgain(userData: updatedUserData)
        try await localDatasource.upsertLastEventId(userId: userId, lastEventId: eventId)
    }
}

private extension CoreEvents {
    var shouldRefreshUserData: Bool {
        users.contains(where: { $0.action == .update }) ||
            addresses.contains(where: { $0.action == .update })
    }
}
