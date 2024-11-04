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

public struct ItemUiModel: Hashable, Equatable, Sendable, Pinnable {
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

    public var hasTotpUri: Bool { totpUri?.isEmpty == false }

    // Add a stored property for the precomputed hash
    private let precomputedHash: Int

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
                isAliasEnabled: Bool) {
        self.itemId = itemId
        self.shareId = shareId
        self.type = type
        self.aliasEmail = aliasEmail
        self.aliasEnabled = aliasEnabled
        self.title = title
        self.description = description
        self.url = url
        self.isAlias = isAlias
        self.totpUri = totpUri
        self.lastUseTime = lastUseTime
        self.modifyTime = modifyTime
        self.state = state
        self.pinned = pinned
        self.isAliasEnabled = isAliasEnabled

        // Precompute the hash value
        var hasher = Hasher()
        hasher.combine(itemId)
        hasher.combine(shareId)
        hasher.combine(type)
        hasher.combine(aliasEmail)
        hasher.combine(aliasEnabled)
        hasher.combine(title)
        hasher.combine(description)
        hasher.combine(url)
        hasher.combine(isAlias)
        hasher.combine(totpUri)
        hasher.combine(lastUseTime)
        hasher.combine(modifyTime)
        hasher.combine(state)
        hasher.combine(pinned)
        hasher.combine(isAliasEnabled)
        precomputedHash = hasher.finalize()
    }

    // Use the precomputed hash in the hash(into:) method
    public func hash(into hasher: inout Hasher) {
        hasher.combine(precomputedHash)
    }
}

extension ItemUiModel: Identifiable {
    public var id: String { itemId + shareId }

    public var aliasDisabled: Bool { !aliasEnabled }
}
