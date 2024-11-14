//
// CredentialItem.swift
// Proton Pass - Created on 08/11/2024.
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

import Client
import Entities
import Foundation

protocol TitledItemIdentifiable: ItemIdentifiable {
    var itemTitle: String { get }
}

extension ItemUiModel: TitledItemIdentifiable {
    var itemTitle: String {
        title
    }
}

enum CredentialItem: TitledItemIdentifiable {
    case uiModel(ItemUiModel)
    case searchResult(ItemSearchResult)

    var shareId: String {
        item.shareId
    }

    var itemId: String {
        item.itemId
    }

    var item: any ItemIdentifiable {
        switch self {
        case let .uiModel(uiModel):
            uiModel
        case let .searchResult(result):
            result
        }
    }

    var itemTitle: String {
        switch self {
        case let .uiModel(uiModel):
            uiModel.title
        case let .searchResult(result):
            result.highlightableTitle.fullText
        }
    }
}
