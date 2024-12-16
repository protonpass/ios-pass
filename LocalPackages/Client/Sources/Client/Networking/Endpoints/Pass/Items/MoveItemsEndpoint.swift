//
// MoveItemsEndpoint.swift
// Proton Pass - Created on 29/03/2023.
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

import Core
import CryptoKit
import Entities
import Foundation
import ProtonCoreNetworking

struct MoveItemsResponse: Decodable, Sendable {
    let items: [Item]
}

public struct MoveItemsRequest: Encodable, Sendable {
    /// Encrypted ID of the destination share
    let shareId: String
    let items: [ItemToBeMoved]

    enum CodingKeys: String, CodingKey {
        case shareId = "ShareID"
        case items = "Items"
    }
}

struct ItemToBeMoved: Codable, Sendable {
    let itemId: String
    let itemKeys: [ItemKey]

    enum CodingKeys: String, CodingKey {
        case itemId = "ItemID"
        case itemKeys = "ItemKeys"
    }
}

struct MoveItemsEndpoint: Endpoint {
    typealias Body = MoveItemsRequest
    typealias Response = MoveItemsResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: MoveItemsRequest?

    init(request: MoveItemsRequest, fromShareId: String) {
        debugDescription = "Move items"
        path = "/pass/v1/share/\(fromShareId)/item/share"
        method = .put
        body = request
    }
}
