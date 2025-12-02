//
// GetListOfFolderEndpoint.swift
// Proton Pass - Created on 28/11/2025.
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

// swiftlint:disable:next todo
// TODO: remove with folder implementation
// periphery:ignore:all

import Core
import Entities
import ProtonCoreNetworking

struct GetListOfFolderResponse: Decodable, Sendable {
    let folders: PaginatedFolders
}

struct GetListOfFolderEndpoint: Endpoint, @unchecked Sendable {
    typealias Body = EmptyRequest
    typealias Response = GetListOfFolderResponse

    let debugDescription: String
    let path: String
    var queries: [String: Any]?

    init(shareId: String,
         sinceToken: String? = nil,
         pageSize: Int = Constants.Utils.defaultPageSize) {
        debugDescription = "Get list of folders for share with ID: \(shareId)"
        path = "pass/v1/share/\(shareId)/folder"

        var queries: [String: Any] = ["PageSize": pageSize]
        if let sinceToken {
            queries["Since"] = sinceToken
        }
        self.queries = queries
    }
}

public struct PaginatedFolders: Decodable, Sendable {
    public let total: Int
    public let lastToken: String?
    public let folders: [Folder]
}
