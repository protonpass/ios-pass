//
// ItemContent+Extensions.swift
// Proton Pass - Created on 07/03/2024.
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

import Entities

// MARK: - Adapters

public extension ItemContent {
    var toItemUiModel: ItemUiModel {
        let note: String
        var url: String?
        var isAlias = false
        var totpUri: String?

        switch contentData {
        case let .login(data):
            note = data.authIdentifier
            url = data.urls.first
            totpUri = data.totpUri

        case .alias:
            note = item.aliasEmail ?? ""
            isAlias = true

        case let .creditCard(data):
            note = data.number.toMaskedCreditCardNumber()

        case .note:
            note = String(self.note.prefix(50))

        case let .identity(data):
            note = data.fullName.concatenateWith(data.email, separator: " / ")

        case .sshKey:
            // swiftlint:disable:next todo
            // TODO: [Custom item] Figure this out later
            note = ""

        case let .wifi(data):
            note = data.ssid

        case let .custom(data):
            // swiftlint:disable:next todo
            // TODO: [Custom item] Figure this out later
            note = ""
        }

        return .init(itemId: item.itemID,
                     shareId: shareId,
                     type: contentData.type,
                     aliasEmail: item.aliasEmail,
                     aliasEnabled: aliasEnabled,
                     title: name,
                     description: note,
                     url: url,
                     isAlias: isAlias,
                     totpUri: totpUri,
                     lastUseTime: item.lastUseTime ?? 0,
                     modifyTime: item.modifyTime,
                     state: item.itemState,
                     pinned: item.pinned,
                     isAliasEnabled: item.isAliasEnabled,
                     isShared: shared)
    }

    func toAuthenticatorItem(totpData: TOTPData) -> AuthenticatorItem? {
        guard let uri = loginItem?.totpUri, !uri.isEmpty else {
            return nil
        }
        let title = totpData.title ?? name
        return AuthenticatorItem(itemId: itemId, shareId: shareId, icon: thumbnailData(), title: title, uri: uri)
    }
}
