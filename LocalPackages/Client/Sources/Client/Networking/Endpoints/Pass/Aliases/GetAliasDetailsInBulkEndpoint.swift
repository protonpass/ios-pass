//
// GetAliasDetailsInBulkEndpoint.swift
// Proton Pass - Created on 06/09/2025.
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

struct GetAliasDetailsInBulkBody: Encodable, Sendable {
    let itemIds: [String]

    enum CodingKeys: String, CodingKey {
        case itemIds = "ItemIDs"
    }
}

struct GetAliasDetailsInBulkResponse: Decodable, Sendable {
    let aliases: [Alias]
}

struct GetAliasDetailsInBulkEndpoint: Endpoint {
    typealias Body = GetAliasDetailsInBulkBody
    typealias Response = GetAliasDetailsInBulkResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: GetAliasDetailsInBulkBody?

    init(shareId: String, itemIds: [String]) {
        debugDescription = "Get alias details in bulk"
        path = "/pass/v1/share/\(shareId)/alias/bulk/get"
        method = .post
        body = .init(itemIds: itemIds)
    }
}
