//
// ItemTypeFilter.swift
// Proton Pass - Created on 31/07/2023.
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

import Client
import Entities
import FactoryKit
import Macro
import ProtonCoreUIFoundations
import UIKit

enum ItemTypeFilterOption: Equatable, Hashable {
    case all
    case precise(ItemContentType)
    case itemSharedWithMe
    case itemSharedByMe

    var isDefault: Bool {
        if case .all = self {
            true
        } else {
            false
        }
    }

    func uiModel(from itemCount: ItemCount) -> ItemTypeFilterOptionUiModel {
        switch self {
        case .all:
            .init(icon: IconProvider.grid2, title: #localized("All"), count: itemCount.total)
        case let .precise(type):
            type.uiModel(from: itemCount)
        case .itemSharedWithMe:
            .init(icon: IconProvider.grid2, title: #localized("Shared with me"), count: itemCount.sharedWithMe)
        case .itemSharedByMe:
            .init(icon: IconProvider.grid2, title: #localized("Shared by me"), count: itemCount.sharedByMe)
        }
    }
}

struct ItemTypeFilterOptionUiModel {
    // periphery:ignore
    let icon: UIImage
    let title: String
    let count: Int
}

private extension ItemContentType {
    func uiModel(from itemCount: ItemCount) -> ItemTypeFilterOptionUiModel {
        let count: Int = switch self {
        case .login:
            itemCount.login
        case .alias:
            itemCount.alias
        case .note:
            itemCount.note
        case .creditCard:
            itemCount.creditCard
        case .identity:
            itemCount.identity
        case .custom, .sshKey, .wifi:
            itemCount.custom
        }
        return .init(icon: regularIcon, title: filterTitle, count: count)
    }
}

/// Conform to `RawRepresentable` to support `@AppStorage`
/// This extension can be removed after moving away from `@AppStorage`
extension ItemTypeFilterOption: RawRepresentable {
    var rawValue: Int {
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

    init?(rawValue: Int) {
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
