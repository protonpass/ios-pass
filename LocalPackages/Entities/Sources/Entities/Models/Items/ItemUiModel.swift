//
// ItemUiModel.swift
// Proton Pass - Created on 03/10/2023.
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

import Foundation

public typealias SectionedItemUiModel = SectionedObjects<ItemUiModel>

public struct ItemUiModel: PrecomputedHashable, Equatable, Sendable, Pinnable {
    // Existing properties
    public let itemId: String
    public let shareId: String
    public let type: ItemContentType
    public let aliasEmail: String?
    public let aliasEnabled: Bool
    public let title: String
    public let description: String
    public let url: String?
    public let isAlias: Bool
    public let isAliasEnabled: Bool
    public let totpUri: String?
    public let lastUseTime: Int64
    public let modifyTime: Int64
    public let state: ItemState
    public let pinned: Bool
    public let shared: Bool
    public let hasEmail: Bool
    public let hasUsername: Bool
    public let hasPassword: Bool

    public var hasTotpUri: Bool { totpUri?.isEmpty == false }

    public let precomputedHash: Int

    public init(itemId: String,
                shareId: String,
                type: ItemContentType,
                aliasEmail: String? = nil,
                aliasEnabled: Bool,
                title: String,
                description: String,
                url: String? = nil,
                isAlias: Bool,
                totpUri: String?,
                lastUseTime: Int64,
                modifyTime: Int64,
                state: ItemState,
                pinned: Bool,
                isAliasEnabled: Bool,
                shared: Bool,
                hasEmail: Bool,
                hasUsername: Bool,
                hasPassword: Bool) {
        // We precompute and cache the hash value
        // because we rely on it a lot to drive SwiftUI's rerendering process
        // the faster we can hash this object, the better the UI performance
        var hasher = Hasher()

        self.itemId = itemId
        hasher.combine(itemId)

        self.shareId = shareId
        hasher.combine(shareId)

        self.type = type
        hasher.combine(type)

        self.aliasEmail = aliasEmail
        hasher.combine(aliasEmail)

        self.aliasEnabled = aliasEnabled
        hasher.combine(aliasEnabled)

        self.title = title
        hasher.combine(title)

        self.description = description
        hasher.combine(description)

        self.url = url
        hasher.combine(url)

        self.isAlias = isAlias
        hasher.combine(isAlias)

        self.totpUri = totpUri
        hasher.combine(totpUri)

        self.lastUseTime = lastUseTime
        hasher.combine(lastUseTime)

        self.modifyTime = modifyTime
        hasher.combine(modifyTime)

        self.state = state
        hasher.combine(state)

        self.pinned = pinned
        hasher.combine(pinned)

        self.isAliasEnabled = isAliasEnabled
        hasher.combine(isAliasEnabled)

        self.shared = shared
        hasher.combine(shared)

        self.hasEmail = hasEmail
        hasher.combine(hasEmail)

        self.hasUsername = hasUsername
        hasher.combine(hasUsername)

        self.hasPassword = hasPassword
        hasher.combine(hasPassword)

        precomputedHash = hasher.finalize()
    }
}

extension ItemUiModel: Identifiable {
    public var id: String { itemId + shareId }

    public var aliasDisabled: Bool { !aliasEnabled }
}

extension ItemUiModel: ItemIdentifiable {}
