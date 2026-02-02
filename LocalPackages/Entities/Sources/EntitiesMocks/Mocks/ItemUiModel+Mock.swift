//  
// ItemUiModel+Mock.swift
// Proton Pass - Created on 02/02/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Foundation
import Entities

public extension ItemUiModel {
    static func mock(
        itemId: String,
        shareId: String,
        folderId: String? = nil,
        isAlias: Bool = false,
        totpUri: String? = nil
    ) -> ItemUiModel {
        ItemUiModel(
            itemId: itemId,
            shareId: shareId,
            folderId: folderId,
            type: .login,
            aliasEnabled: false,
            title: "Item \(itemId)",
            description: "Description for \(itemId)",
            isAlias: isAlias,
            totpUri: totpUri,
            lastUseTime: 123_456_678,
            modifyTime: 123_456_789,
            state: .active,
            pinned: false,
            isAliasEnabled: false,
            shared: false,
            hasEmail: true,
            hasUsername: true,
            hasPassword: true
        )
    }
}
