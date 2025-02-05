//
// ImportItemsEndpoint.swift
// Proton Pass - Created on 05/02/2025.
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

import Core
import CryptoKit
import Entities
import Foundation
import ProtonCoreNetworking

struct ImportItemsResponse: Decodable, Sendable {
    let revisions: Items
}

struct Items: Decodable, Sendable {
    let revisionsData: [Item]
}

struct ImportItemsRequest: Encodable, Sendable {
    let items: [ItemToImport]

    enum CodingKeys: String, CodingKey {
        case items = "Items"
    }
}

public struct ItemToImport: Encodable, Sendable {
    let item: CreateItemRequest

    enum CodingKeys: String, CodingKey {
        case item = "Item"
    }

    init(vaultKey: DecryptedShareKey,
         itemContent: any ProtobufableItemContentProtocol) throws {
        let itemKey = try Data.random()
        let encryptedContent = try AES.GCM.seal(itemContent.data(),
                                                key: itemKey,
                                                associatedData: .itemContent)

        let encryptedItemKey = try AES.GCM.seal(itemKey,
                                                key: vaultKey.keyData,
                                                associatedData: .itemKey)

        item = .init(keyRotation: vaultKey.keyRotation,
                     contentFormatVersion: Int16(Constants.ContentFormatVersion.item),
                     content: encryptedContent.base64EncodedString(),
                     itemKey: encryptedItemKey.base64EncodedString())
    }
}

struct ImportItemsEndpoint: Endpoint {
    typealias Body = ImportItemsRequest
    typealias Response = ImportItemsResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: ImportItemsRequest?

    init(shareId: String, items: [ItemToImport]) {
        debugDescription = "Import items"
        path = "/pass/v1/share/\(shareId)/item/import/batch"
        method = .post
        body = .init(items: items)
    }
}
