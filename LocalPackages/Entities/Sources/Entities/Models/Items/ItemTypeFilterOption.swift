//
// ItemTypeFilterOption.swift
// Proton Pass - Created on 27/01/2026.
// Copyright (c) 2026 Proton Technologies AG
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

/// Conform to `RawRepresentable` to support `@AppStorage`
/// Can be removed after moving away from `@AppStorage`
public enum ItemTypeFilterOption: Sendable, Equatable, Hashable, RawRepresentable {
    case all
    case precise(ItemContentType)
    case itemSharedWithMe
    case itemSharedByMe

    public var rawValue: Int {
        switch self {
        case .all:
            -1

        case let .precise(type):
            type.rawValue

        case .itemSharedWithMe:
            300

        case .itemSharedByMe:
            301
        }
    }

    public var isDefault: Bool {
        if case .all = self {
            true
        } else {
            false
        }
    }

    public init?(rawValue: Int) {
        switch rawValue {
        case ItemTypeFilterOption.all.rawValue:
            self = .all

        case ItemTypeFilterOption.itemSharedWithMe.rawValue:
            self = .itemSharedWithMe

        case ItemTypeFilterOption.itemSharedByMe.rawValue:
            self = .itemSharedByMe

        default:
            if let type = ItemContentType(rawValue: rawValue) {
                self = .precise(type)
            } else {
                return nil
            }
        }
    }
}
