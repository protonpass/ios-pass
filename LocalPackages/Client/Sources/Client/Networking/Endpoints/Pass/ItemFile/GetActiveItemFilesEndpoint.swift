//
// GetActiveItemFilesEndpoint.swift
// Friday the 13th
// Proton Pass - Created on 13/12/2024.
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

public struct GetActiveItemFilesResponse: Decodable, Sendable {
    public let files: PaginatedActiveItemFiles
}

public struct PaginatedActiveItemFiles: Decodable, Sendable {
    public let files: [ItemFile]
    public let total: Int
    public let lastID: String?
}

struct GetActiveItemFilesEndpoint: Endpoint, @unchecked Sendable {
    typealias Body = EmptyRequest
    typealias Response = GetActiveItemFilesResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var parameters: [String: Any]?

    init(item: any ItemIdentifiable, lastId: String?) {
        debugDescription = "Get active files of an item"
        path = "/pass/v1/share/\(item.shareId)/item/\(item.itemId)/files"
        method = .get
        if let lastId {
            parameters = ["Since": lastId]
        }
    }
}
