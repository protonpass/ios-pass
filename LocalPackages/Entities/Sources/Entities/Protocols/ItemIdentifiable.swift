//
// ItemIdentifiable.swift
// Proton Pass - Created on 09/11/2023.
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
//

import Foundation

/// Should be conformed by structs that represent items differently.
/// E.g: for different purposes like listing & searching
public protocol ItemIdentifiable: Sendable, CustomDebugStringConvertible {
    var shareId: String { get }
    var itemId: String { get }
}

public extension ItemIdentifiable {
    var debugDescription: String {
        "Item \(itemId) - Share \(shareId)"
    }
}

public extension Array where Element: ItemIdentifiable {
    func contains(_ item: some ItemIdentifiable) -> Bool {
        contains(where: { $0.shareId == item.shareId && $0.itemId == item.itemId })
    }

    mutating func remove(item: some ItemIdentifiable) {
        removeAll { $0.shareId == item.shareId && $0.itemId == item.itemId }
    }

    func removing(item: some ItemIdentifiable) -> Self {
        var copiedArray = self
        copiedArray.remove(item: item)
        return copiedArray
    }
}
