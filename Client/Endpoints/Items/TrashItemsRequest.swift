//
// TrashItemsRequest.swift
// Proton Pass - Created on 08/09/2022.
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

import Foundation

public struct TrashItemsRequest: Encodable {
    public let items: [ItemToBeTrashed]

    enum CodingKeys: String, CodingKey {
        case items = "Items"
    }

    public init(items: [ItemToBeTrashed]) {
        self.items = items
    }
}

public struct ItemToBeTrashed: Encodable {
    public let itemID: String
    public let revision: Int16

    enum CodingKeys: String, CodingKey {
        case itemID = "ItemID"
        case revision = "Revision"
    }
}

// swiftlint:disable explicit_enum_raw_value
extension ItemToBeTrashed: Decodable {
    enum DecodingKeys: String, CodingKey {
        case itemID, revision
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DecodingKeys.self)
        self.itemID = try container.decode(String.self, forKey: .itemID)
        self.revision = try container.decode(Int16.self, forKey: .revision)
    }
}
