//
// ItemUiModel.swift
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

struct ItemUiModel: ItemTypeIdentifiable, ItemThumbnailable, Hashable {
    let itemId: String
    let shareId: String
    let type: ItemContentType
    let title: String
    let description: String
    let url: String?
    let isAlias: Bool
    let hasTotpUri: Bool
    let lastUseTime: Int64
    let modifyTime: Int64
    let state: ItemState
}

extension ItemUiModel: Identifiable {
    var id: String { itemId + shareId }
}

extension ItemUiModel: DateSortable {
    var dateForSorting: Date {
        Date(timeIntervalSince1970: TimeInterval(max(lastUseTime, modifyTime)))
    }
}

extension ItemUiModel: AlphabeticalSortable {
    var alphabeticalSortableString: String { title }
}

extension SymmetricallyEncryptedItem {
    func toItemUiModel(_ symmetricKey: SymmetricKey) throws -> ItemUiModel {
        let encryptedItemContent = try getEncryptedItemContent()
        let name = try symmetricKey.decrypt(encryptedItemContent.name)

        let note: String
        let url: String?
        let isAlias: Bool
        let hasTotpUri: Bool

        switch encryptedItemContent.contentData {
        case .login(let data):
            note = try symmetricKey.decrypt(data.username)
            if let firstUrl = data.urls.first {
                url = try symmetricKey.decrypt(firstUrl)
            } else {
                url = nil
            }
            isAlias = false
            let totpUri = try symmetricKey.decrypt(data.totpUri)
            hasTotpUri = !totpUri.isEmpty

        case .alias:
            note = item.aliasEmail ?? ""
            url = nil
            isAlias = true
            hasTotpUri = false

        default:
            note = try String(symmetricKey.decrypt(encryptedItemContent.note).prefix(50))
            url = nil
            isAlias = false
            hasTotpUri = false
        }

        return .init(itemId: encryptedItemContent.item.itemID,
                     shareId: encryptedItemContent.shareId,
                     type: encryptedItemContent.contentData.type,
                     title: name,
                     description: note,
                     url: url,
                     isAlias: isAlias,
                     hasTotpUri: hasTotpUri,
                     lastUseTime: item.lastUseTime ?? 0,
                     modifyTime: item.modifyTime,
                     state: encryptedItemContent.item.itemState)
    }
}
