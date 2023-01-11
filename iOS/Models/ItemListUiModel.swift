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
import ProtonCore_UIFoundations
import UIComponents
import UIKit

struct ItemListUiModel: ItemIdentifiable, GenericItemProtocol {
    let itemId: String
    let shareId: String
    let type: ItemContentType
    let title: String
    let createTime: Int64
    let modifyTime: Int64
    let detail: GenericItemDetail

    var icon: UIImage { type.icon }
    var iconTintColor: UIColor { type.iconTintColor }
}

extension ItemListUiModel: Identifiable {
    var id: String { itemId + shareId }
}

extension ItemListUiModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(itemId)
        hasher.combine(shareId)
        hasher.combine(type)
        hasher.combine(title)
        hasher.combine(createTime)
        hasher.combine(modifyTime)
        hasher.combine(detail)
    }
}

extension SymmetricallyEncryptedItem {
    func toItemListUiModel(_ symmetricKey: SymmetricKey) async throws -> ItemListUiModel {
        let encryptedItemContent = try getEncryptedItemContent()
        let name = try symmetricKey.decrypt(encryptedItemContent.name)

        let note: String?
        let notePlaceholder: String?
        switch encryptedItemContent.contentData {
        case .login(let username, _, _):
            note = try symmetricKey.decrypt(username)
            notePlaceholder = "No username"
        case .alias:
            note = item.aliasEmail
            notePlaceholder = nil
        default:
            note = try symmetricKey.decrypt(encryptedItemContent.note)
            notePlaceholder = "Empty note"
        }

        let detail: GenericItemDetail
        if let note, !note.isEmpty {
            detail = .value(note)
        } else {
            detail = .placeholder(notePlaceholder)
        }

        return .init(itemId: encryptedItemContent.item.itemID,
                     shareId: encryptedItemContent.shareId,
                     type: encryptedItemContent.contentData.type,
                     title: name,
                     createTime: item.createTime,
                     modifyTime: item.modifyTime,
                     detail: detail)
    }
}
