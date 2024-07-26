//
// IDs.swift
// Proton Pass - Created on 29/01/2024.
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
//

import Foundation

/// A combination of `shareId` and `itemId` of an item to make up an unique ID
public struct IDs: CodableBase64, ItemIdentifiable, Sendable, Hashable {
    public let shareId: String
    public let itemId: String

    public init(shareId: String, itemId: String) {
        self.shareId = shareId
        self.itemId = itemId
    }
}
