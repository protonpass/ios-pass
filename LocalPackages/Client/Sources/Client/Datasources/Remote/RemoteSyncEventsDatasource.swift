//
// RemoteSyncEventsDatasource.swift
// Proton Pass - Created on 27/10/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public protocol RemoteSyncEventsDatasourceProtocol: Sendable {
    func getEvents(userId: String, shareId: String, lastEventId: String) async throws -> SyncEvents
}

public final class RemoteSyncEventsDatasource: RemoteDatasource, RemoteSyncEventsDatasourceProtocol,
    @unchecked Sendable {}

public extension RemoteSyncEventsDatasource {
    func getEvents(userId: String, shareId: String, lastEventId: String) async throws -> SyncEvents {
        let endpoint = GetEventsEndpoint(shareId: shareId, lastEventId: lastEventId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.events
    }
}
