//
// GetUsersLinkedToVaultShareEndpoint.swift
// Proton Pass - Created on 11/07/2023.
// Copyright (c) 2023 Proton Technologies AG
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

public struct PaginatedUsersLinkedToShare: Decodable, Sendable {
    public let shares: [UserShareInfos]
    public let total: Int
    public let lastToken: String?

    public init(shares: [UserShareInfos], total: Int, lastToken: String?) {
        self.shares = shares
        self.total = total
        self.lastToken = lastToken
    }
}

struct GetUsersLinkedToVaultShareEndpoint: @unchecked Sendable, Endpoint {
    typealias Body = EmptyRequest
    typealias Response = PaginatedUsersLinkedToShare

    var debugDescription: String
    var path: String
    var queries: [String: Any]?

    init(for shareId: String, lastToken: String? = nil, pageSize: Int? = nil) {
        debugDescription = "Get users that have access to the whole vault"
        path = "/pass/v1/share/\(shareId)/user"
        var queries: [String: Any] = [:]
        if let pageSize {
            queries["PageSize"] = pageSize
        }
        if let lastToken {
            queries["Since"] = lastToken
        }
        self.queries = queries
    }
}
