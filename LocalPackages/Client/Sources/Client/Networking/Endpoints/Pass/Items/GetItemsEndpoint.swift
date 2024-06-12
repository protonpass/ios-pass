//
// GetItemsEndpoint.swift
// Proton Pass - Created on 10/08/2022.
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

import Entities
import ProtonCoreNetworking

struct GetItemsResponse: Decodable, Sendable {
    let items: ItemsPaginated
}

struct GetItemsEndpoint: Endpoint, @unchecked Sendable {
    typealias Body = EmptyRequest
    typealias Response = GetItemsResponse

    var debugDescription: String
    var path: String
    var queries: [String: Any]?

    init(shareId: String, sinceToken: String?, pageSize: Int) {
        debugDescription = "Get items for share"
        path = "/pass/v1/share/\(shareId)/item"

        var queries: [String: Any] = ["PageSize": pageSize]
        if let sinceToken {
            queries["Since"] = sinceToken
        }
        self.queries = queries
    }
}
