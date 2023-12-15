//
// GetShareKeysEndpoint.swift
// Proton Pass - Created on 19/07/2022.
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
import ProtonCoreServices

public struct GetShareKeysResponse: Decodable, Sendable {
    let shareKeys: ShareKeys
}

public struct GetShareKeysEndpoint: Endpoint, @unchecked Sendable {
    public typealias Body = EmptyRequest
    public typealias Response = GetShareKeysResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod
    public var queries: [String: Any]?

    public init(shareId: String, page: Int, pageSize: Int) {
        debugDescription = "Get keys for share"
        path = "/pass/v1/share/\(shareId)/key"
        method = .get
        queries = .paginationQuery(page: page, pageSize: pageSize)
    }
}
