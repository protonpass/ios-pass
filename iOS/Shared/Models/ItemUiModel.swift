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
import Entities

struct ItemUiModel: ItemTypeIdentifiable, ItemThumbnailable, Hashable, Equatable {
    let itemId: String
    let shareId: String
    let type: ItemContentType
    let aliasEmail: String?
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
        let itemContent = try getItemContent(symmetricKey: symmetricKey)

        let note: String
        var url: String?
        var isAlias = false
        var hasTotpUri = false

        switch itemContent.contentData {
        case let .login(data):
            note = data.username
            url = data.urls.first
            hasTotpUri = !data.totpUri.isEmpty

        case .alias:
            note = item.aliasEmail ?? ""
            isAlias = true

        case let .creditCard(data):
            note = data.number.toMaskedCreditCardNumber()

        case .note:
            note = String(itemContent.note.prefix(50))
        }

        return .init(itemId: item.itemID,
                     shareId: shareId,
                     type: itemContent.contentData.type,
                     aliasEmail: item.aliasEmail,
                     title: itemContent.name,
                     description: note,
                     url: url,
                     isAlias: isAlias,
                     hasTotpUri: hasTotpUri,
                     lastUseTime: item.lastUseTime ?? 0,
                     modifyTime: item.modifyTime,
                     state: item.itemState)
    }
}
