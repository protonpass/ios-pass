//
// SymmetricallyEncryptedItem+Extensions.swift
// Proton Pass - Created on 24/11/2023.
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

import CryptoKit
import Entities

public extension SymmetricallyEncryptedItem {
    func toSearchEntryUiModel(_ symmetricKey: SymmetricKey) throws -> SearchEntryUiModel {
        let itemContent = try getItemContent(symmetricKey: symmetricKey)

        let note: String?
        var url: String?

        switch itemContent.contentData {
        case let .login(data):
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
