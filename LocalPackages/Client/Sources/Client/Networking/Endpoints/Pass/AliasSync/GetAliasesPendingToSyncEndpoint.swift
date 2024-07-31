//
// GetAliasesPendingToSyncEndpoint.swift
// Proton Pass - Created on 31/07/2024.
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

import Entities
import ProtonCoreNetworking

struct GetAliasesPendingToSyncResponse: Decodable, Sendable {
    let pendingAliases: PaginatedPendingAliases
}

struct GetAliasesPendingToSyncEndpoint: Endpoint, @unchecked Sendable {
    typealias Body = EmptyRequest
    typealias Response = GetAliasesPendingToSyncResponse

    var debugDescription: String
    var path: String
    var queries: [String: Any]?

    init(since: String?, pageSize: Int) {
        debugDescription = "Get aliases pending to sync"
        path = "/pass/v1/alias_sync/pending"

        var queries: [String: Any] = ["PageSize": pageSize]
        if let since {
            queries["Since"] = since
        }
        self.queries = queries
    }
}
