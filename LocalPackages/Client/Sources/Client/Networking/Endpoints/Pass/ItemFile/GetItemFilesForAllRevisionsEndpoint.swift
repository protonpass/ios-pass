//
// GetItemFilesForAllRevisionsEndpoint.swift
// Proton Pass - Created on 30/12/2024.
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

struct GetItemFilesForAllRevisionsEndpoint: Endpoint, @unchecked Sendable {
    typealias Body = EmptyRequest
    typealias Response = GetItemFilesResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var parameters: [String: Any]?

    init(item: any ItemIdentifiable, lastId: String?) {
        debugDescription = "Get item files for all revisions"
        path = "/pass/v1/share/\(item.shareId)/item/\(item.itemId)/revisions/files"
        method = .get
        if let lastId {
            parameters = ["Since": lastId]
        }
    }
}
