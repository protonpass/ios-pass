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
import ProtonCore_UIFoundations
import UIKit

enum ItemTypeFilterOption: Equatable, Hashable {
    case all
    case precise(ItemContentType)

    static var allCases: [ItemTypeFilterOption] {
        // We want to control the order of appearance so we construct the array manually
        // instead of looping through "ItemContentType.allCases"
        let allCases: [ItemTypeFilterOption] = [
            .all,
            .precise(.login),
            .precise(.alias),
            .precise(.creditCard),
            .precise(.note)
        ]
        assert(allCases.count == ItemContentType.allCases.count + 1, "Some type is missing")
        return allCases
    }

    func uiModel(from itemCount: ItemCount) -> ItemTypeFilterOptionUiModel {
        switch self {
        case .all:
            return .init(icon: IconProvider.grid2, title: "All".localized, count: itemCount.total)
        case let .precise(type):
            return type.uiModel(from: itemCount)
        }
    }
}

struct ItemTypeFilterOptionUiModel {
    let icon: UIImage
    let title: String
    let count: Int
}

private extension ItemContentType {
    func uiModel(from itemCount: ItemCount) -> ItemTypeFilterOptionUiModel {
        let count: Int
        switch self {
        case .login:
            count = itemCount.login
        case .alias:
            count = itemCount.alias
        case .note:
            count = itemCount.note
        case .creditCard:
            count = itemCount.creditCard
        }
        return .init(icon: regularIcon, title: filterTitle, count: count)
    }
}
