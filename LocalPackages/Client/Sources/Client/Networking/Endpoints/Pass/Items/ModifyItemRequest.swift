//
// ModifyItemRequest.swift
// Proton Pass - Created on 13/09/2022.
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

struct ModifyItemRequest: Encodable, Sendable {
    /// Pairs of item IDs with their latest revision
    let items: [ItemToBeModified]

    /// Skip checking that the items are in the trash. Allows to delete directly
    let skipTrash: Bool

    enum CodingKeys: String, CodingKey {
        case items = "Items"
        case skipTrash = "SkipTrash"
    }

//    init(items: [ItemToBeModified], skipTrash: Bool) {
//        self.items = items
//        self.skipTrash = skipTrash
//    }

    init(items: [Item], skipTrash: Bool) {
        self.items = items.map { .init(itemID: $0.itemID, revision: $0.revision) }
        self.skipTrash = skipTrash
    }
}

struct ModifyItemResponse: Decodable, Sendable {
    let items: [ModifiedItem]
}

/// To be deleted/trashed/untrashed
struct ItemToBeModified: Encodable, Sendable {
    let itemID: String
    let revision: Int64

    enum CodingKeys: String, CodingKey {
        case itemID = "ItemID"
        case revision = "Revision"
    }
}

/// Trashed/untrashed item
public struct ModifiedItem: Decodable, Sendable {
    public let itemID: String
    public let revision: Int64
    public let state: Int64
    public let modifyTime: Int64
    public let revisionTime: Int64
    public let flags: Int
}
