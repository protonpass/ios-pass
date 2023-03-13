//
// ItemListUiModel.swift
// Proton Pass - Created on 20/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

struct ItemListUiModelV2: ItemIdentifiable, Hashable {
    let itemId: String
    let shareId: String
    let type: ItemContentType
    let title: String
    let description: String?
    let lastUseTime: Int64
    let modifyTime: Int64
}

extension ItemListUiModelV2: Identifiable {
    var id: String { itemId + shareId }
}

extension ItemListUiModelV2: DateSortable {
    var dateForSorting: Date {
        Date(timeIntervalSince1970: TimeInterval(max(lastUseTime, modifyTime)))
    }
}

extension ItemListUiModelV2: AlphabeticalSortable {
    var alphabeticalSortableString: String { title }
}

extension SymmetricallyEncryptedItem {
    func toItemListUiModelV2(_ symmetricKey: SymmetricKey) throws -> ItemListUiModelV2 {
        let encryptedItemContent = try getEncryptedItemContent()
        let name = try symmetricKey.decrypt(encryptedItemContent.name)

        var note: String?
        switch encryptedItemContent.contentData {
        case .login(let data):
            note = try symmetricKey.decrypt(data.username)
        case .alias:
            note = item.aliasEmail
        default:
            note = nil
        }

        return .init(itemId: encryptedItemContent.item.itemID,
                     shareId: encryptedItemContent.shareId,
                     type: encryptedItemContent.contentData.type,
                     title: name,
                     description: note?.isEmpty == true ? nil : note,
                     lastUseTime: item.lastUseTime ?? 0,
                     modifyTime: item.modifyTime)
    }
}
