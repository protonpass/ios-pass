//
// GetAliasContactsEndpoint.swift
// Proton Pass - Created on 02/10/2024.
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

public struct GetAliasContactsQuery: Sendable {
    public let lastContactId: Int?

    public init(lastContactId: Int?) {
        self.lastContactId = lastContactId
    }
}

public struct PaginatedAliasContacts: Decodable, Sendable, Equatable, Hashable {
    public let contacts: [AliasContact]
    public let total: Int
    public let lastID: Int
}

struct GetAliasContactsEndpoint: Endpoint, @unchecked Sendable {
    typealias Body = EmptyRequest
    typealias Response = PaginatedAliasContacts

    var debugDescription: String
    var path: String
    var parameters: [String: Any]?

    init(shareId: String, itemId: String, query: GetAliasContactsQuery) {
        debugDescription = "Get alias contact details"
        path = "/pass/v1/share/\(shareId)/alias/\(itemId)/contact"
        if let lastContactId = query.lastContactId {
            parameters = ["Since": lastContactId]
        }
    }
}
