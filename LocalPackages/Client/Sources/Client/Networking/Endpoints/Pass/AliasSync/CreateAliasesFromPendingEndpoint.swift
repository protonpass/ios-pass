//
// CreateAliasesFromPendingEndpoint.swift
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

struct CreateAliasesFromPendingResponse: Decodable, Sendable {
    let revisions: CreateAliasesData

    struct CreateAliasesData: Decodable {
        let revisionsData: [Item]
        let total: Int
        let lastToken: String?
    }
}

public struct CreateAliasesFromPendingRequest: Encodable, Sendable {
    let items: [AliasesItemPendingInfo]

    enum CodingKeys: String, CodingKey {
        case items = "Items"
    }
}

struct AliasesItemPendingInfo: Encodable, Sendable {
    let pendingAliasID: String
    let item: CreateItemRequest

    enum CodingKeys: String, CodingKey {
        case pendingAliasID = "PendingAliasID"
        case item = "Item"
    }
}

struct CreateAliasesFromPendingEndpoint: Endpoint {
    typealias Body = CreateAliasesFromPendingRequest
    typealias Response = CreateAliasesFromPendingResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: CreateAliasesFromPendingRequest?

    init(shareId: String, request: CreateAliasesFromPendingRequest) {
        debugDescription = "Create alias from pending status"
        path = "/pass/v1/alias_sync/share/\(shareId)/create"
        method = .post
        body = request
    }
}
