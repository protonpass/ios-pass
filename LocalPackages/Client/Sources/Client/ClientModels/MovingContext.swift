//
// MovingContext.swift
// Proton Pass - Created on 03/10/2023.
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

import Entities
import Foundation

public enum MovingContext: Sendable, Equatable, Hashable {
    case singleItem(any ItemTypeIdentifiable)
    case allItems(Share)
    case selectedItems([any ItemIdentifiable])
}

public extension MovingContext {
    static func == (lhs: MovingContext, rhs: MovingContext) -> Bool {
        switch (lhs, rhs) {
        case let (.singleItem(lhsItem), .singleItem(rhsItem)):
            lhsItem.isEqual(with: rhsItem)
        case let (.allItems(lhsShare), .allItems(rhsShare)):
            lhsShare.id == rhsShare.id
        case let (.selectedItems(lhsItems), .selectedItems(rhsItems)):
            lhsItems.count == rhsItems.count
        default:
            false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .singleItem(item):
            hasher.combine(item.shareId + item.itemId)
        case let .allItems(share):
            hasher.combine(share.id)
        case let .selectedItems(items):
            hasher.combine(items.map { $0.shareId + $0.itemId })
        }
    }
}
