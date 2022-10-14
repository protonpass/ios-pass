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
import UIComponents
import UIKit

struct ItemListUiModel: GenericItemProtocol {
    let itemId: String
    let shareId: String
    let type: ItemContentType
    let icon: UIImage
    let title: String
    let detail: String?
}

extension SymmetricallyEncryptedItem {
    func toItemListUiModel(_ symmetricKey: SymmetricKey) async throws -> ItemListUiModel {
        let encryptedItemContent = try getEncryptedItemContent()
        let name = try symmetricKey.decrypt(encryptedItemContent.name)
        let note: String
        switch encryptedItemContent.contentData {
        case .login(let username, _, _):
            note = try symmetricKey.decrypt(username)
        default:
            note = try symmetricKey.decrypt(encryptedItemContent.note)
        }
        return .init(itemId: encryptedItemContent.itemId,
                     shareId: encryptedItemContent.shareId,
                     type: encryptedItemContent.contentData.type,
                     icon: encryptedItemContent.contentData.type.icon,
                     title: name,
                     detail: note)
    }
}
