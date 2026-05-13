//
// RemoteCoreEventIdDatasource.swift
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

public protocol RemoteCoreEventIdDatasourceProtocol: Sendable {
    func getLatestCoreEventId(userId: String) async throws -> String
    func getCoreEvents(userId: String, lastEventId: String) async throws -> CoreEvents
}

public final class RemoteCoreEventIdDatasource: RemoteDatasource, RemoteCoreEventIdDatasourceProtocol,
    @unchecked Sendable {}

public extension RemoteCoreEventIdDatasource {
    func getLatestCoreEventId(userId: String) async throws -> String {
        let endpoint = GetLatestCoreEventIdEndpoint()
        let result = try await exec(userId: userId, endpoint: endpoint)
        return result.eventID
    }

    func getCoreEvents(userId: String, lastEventId: String) async throws -> CoreEvents {
        let endpoint = GetCoreEventsEndpoint(lastEventId: lastEventId)
        return try await exec(userId: userId, endpoint: endpoint)
    }
}
