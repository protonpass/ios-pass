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
public protocol ItemIdentifiable: Sendable, CustomDebugStringConvertible, Equatable {
    var shareId: String { get }
    var itemId: String { get }
    var folderId: String? { get }
}

public extension ItemIdentifiable {
    var parentId: String {
        folderId ?? shareId
    }

    var fullParentId: String {
        if let folderId {
            return folderId + shareId
        }
        return shareId
    }
}

public extension ItemIdentifiable {
    var ids: IDs {
        .init(shareId: shareId, itemId: itemId)
    }
}

public extension ItemIdentifiable {
    func isEqual(with otherItem: any ItemIdentifiable) -> Bool {
        shareId == otherItem.shareId && itemId == otherItem.itemId
    }
}

public extension ItemIdentifiable {
    var debugDescription: String {
        "Item \(itemId) - Share \(shareId)"
    }
}

public extension Array where Element: ItemIdentifiable {
    /// Items belonging to `shareId`, narrowed to `containerIds` when given.
    /// `nil` means the whole share at any depth; a set means those containers only, so callers
    /// pass a folder's subtree to include descendants or a single id to exclude them.
    func scoped(toShare shareId: String, containerIds: Set<String>?) -> Self {
        filter { item in
            guard item.shareId == shareId else { return false }
            guard let containerIds else { return true }
            return containerIds.contains(item.parentId)
        }
    }

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
