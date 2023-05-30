//
// SearchEntryUiModel.swift
// Proton Pass - Created on 17/03/2023.
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
import CryptoKit

struct SearchEntryUiModel: ItemIdentifiable {
    let itemId: String
    let shareId: String
    let type: ItemContentType
    let title: String
    let url: String?
    let description: String?
}

extension SearchEntryUiModel: Identifiable {
    var id: String { itemId + shareId }
}

extension SearchEntryUiModel: ItemThumbnailable {}

extension SearchEntryUiModel: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.shareId == rhs.shareId && lhs.itemId == rhs.itemId
    }
}

extension SymmetricallyEncryptedItem {
    func toSearchEntryUiModel(_ symmetricKey: SymmetricKey) throws -> SearchEntryUiModel {
        let itemContent = try getItemContent(symmetricKey: symmetricKey)

        let note: String?
        var url: String?

        switch itemContent.contentData {
        case .login(let data):
            note = data.username
            url = data.urls.first
        case .alias:
            note = item.aliasEmail
        default:
            note = itemContent.note
        }

        return .init(itemId: item.itemID,
                     shareId: shareId,
                     type: itemContent.contentData.type,
                     title: itemContent.name,
                     url: url,
                     description: note?.isEmpty == true ? nil : note)
    }
}
