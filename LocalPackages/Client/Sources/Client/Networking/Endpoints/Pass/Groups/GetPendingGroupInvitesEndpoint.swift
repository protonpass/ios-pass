//
// GetPendingGroupInvitesEndpoint.swift
// Proton Pass - Created on 30/07/2025.
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

import Entities
import ProtonCoreNetworking

public struct PaginatedGroupInvites: Decodable, Sendable {
    public let invites: [GroupInvite]
    public let total: Int
    public let lastID: String?
}

struct GetPendingGroupInvitesResponse: Decodable {
    let invites: PaginatedGroupInvites
}

struct GetPendingGroupInvitesEndpoint: Endpoint, @unchecked Sendable {
    typealias Body = EmptyRequest
    typealias Response = GetPendingGroupInvitesResponse

    let debugDescription: String
    let path: String
    let queries: [String: Any]?

    init(sinceToken: String?, eventToken: String?) {
        debugDescription = "Get a list of group invites for a specific user"
        path = "/pass/v1/invite/group"

        var queries: [String: Any] = [:]
        if let sinceToken {
            queries["Since"] = sinceToken
        }

        if let eventToken {
            queries = ["EventToken": eventToken]
        }
        self.queries = queries
    }
}
