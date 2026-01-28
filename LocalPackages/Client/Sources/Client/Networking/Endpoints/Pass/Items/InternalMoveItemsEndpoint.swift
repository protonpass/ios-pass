//
// InternalMoveItemsEndpoint.swift
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

import CryptoKit
import Entities
import Foundation
import ProtonCoreNetworking

struct InternalMoveItemsResponse: Decodable, Sendable {
    let items: [ModifiedItem]
}

public struct InternalMoveItemsRequest: Encodable, Sendable {
    /// Encrypted ID of the destination share
    let folderId: String?
    let items: [InternalItemToBeMoved]

    enum CodingKeys: String, CodingKey {
        case folderId = "FolderID"
        case items = "Items"
    }
}

struct InternalItemToBeMoved: Codable, Sendable {
    let itemId: String
    let itemKeys: [ItemKey]

    enum CodingKeys: String, CodingKey {
        case itemId = "ItemID"
        case itemKeys = "ItemKeys"
    }
}

struct InternalMoveItemsEndpoint: Endpoint {
    typealias Body = InternalMoveItemsRequest
    typealias Response = InternalMoveItemsResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: InternalMoveItemsRequest?

    init(request: InternalMoveItemsRequest, shareId: String) {
        debugDescription = "Move items internally in share"
        path = "/pass/v1/share/\(shareId)/item/folder"
        method = .put
        body = request
    }
}

// public struct TestItemKey: Codable, Equatable, Hashable, Sendable {
//    /// Encrypted key encoded in base64
//    public let itemKey: String
//    public let keyRotation: Int64
//
//    public init(key: String, keyRotation: Int64) {
//        itemKey = key
//        self.keyRotation = keyRotation
//    }
//
//    enum CodingKeys: String, CodingKey {
//        case itemKey = "ItemKey"
//        case keyRotation = "KeyRotation"
//    }
//
//    // custom decoder
//    public init(from decoder: any Decoder) throws {
//        // keys that work with `JSONDecoder.KeyDecodingStrategy.decapitaliseFirstLetter`
//        enum DecodingKeys: String, CodingKey {
//            case itemKey
//            case keyRotation
//        }
//        let container = try decoder.container(keyedBy: DecodingKeys.self)
//        itemKey = try container.decode(String.self, forKey: .itemKey)
//        keyRotation = try container.decode(Int64.self, forKey: .keyRotation)
//    }
// }
