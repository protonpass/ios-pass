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

public struct ModifyItemRequest: Encodable {
    public let items: [ItemToBeModified]

    enum CodingKeys: String, CodingKey {
        case items = "Items"
    }

    public init(items: [ItemRevision]) {
        self.items = items.map { .init(itemID: $0.itemID, revision: $0.revision) }
    }

    public init(items: [ItemToBeModified]) {
        self.items = items
    }
}

public struct ModifyItemResponse: Decodable {
    public let code: Int
    public let items: [ModifiedItem]
}

/// To be deleted/trashed/untrashed
public struct ItemToBeModified: Encodable {
    public let itemID: String
    public let revision: Int16

    enum CodingKeys: String, CodingKey {
        case itemID = "ItemID"
        case revision = "Revision"
    }
}

/// Trashed/untrashed item
public struct ModifiedItem: Decodable {
    public let itemID: String
    public let revision: Int16
    public let state: Int16
    public let modifyTime: Int64
    public let revisionTime: Int64
}
