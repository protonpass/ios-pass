//
// Item.swift
// Proton Pass - Created on 13/08/2022.
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

public struct ItemsPaginated: Decodable, Sendable {
    public let total: Int
    public let lastToken: String?
    public let revisionsData: [Item]
}

public struct Item: Decodable, Equatable, Sendable, Hashable {
    public let itemID: String
    public let revision: Int64
    public let contentFormatVersion: Int64
    public let keyRotation: Int64
    public let content: String

    /// Base64 encoded item key. Only for vault shares.
    public let itemKey: String?

    /// Revision state. Values: 1 = Active, 2 = Trashed
    public let state: Int64

    public let pinned: Bool

    public let pinTime: Int?

    /// In case this item contains an alias, this is the email address for the alias
    public let aliasEmail: String?

    /// Creation time of the item
    public let createTime: Int64

    /// Time of last update of the item
    public let modifyTime: Int64

    /// Time when the item was last used
    public let lastUseTime: Int64?

    /// Creation time of this revision
    public let revisionTime: Int64

    /// Flags for this item. Possible values:
    /// - SkipHealthCheck: 1<<0 = 1, if first bit of Int is 1 then the item should not be monitored in `Pass
    /// - EmailBreached: 1<<1 = 1, if second bit of Int is 1 then the item has a breached email
    /// - AliasSyncEnable: 1<<2 = 1, if third bit of Int is 1 then the alias item in sync betweenSL and Pass
    /// This is being implemented in the `ItemFlagable` protocol
    /// Monitor`
    public let flags: Int

    /// Enum representation of `state`
    public var itemState: ItemState { .init(rawValue: state) ?? .active }

    public init(itemID: String,
                revision: Int64,
                contentFormatVersion: Int64,
                keyRotation: Int64,
                content: String,
                itemKey: String?,
                state: Int64,
                pinned: Bool,
                pinTime: Int?,
                aliasEmail: String?,
                createTime: Int64,
                modifyTime: Int64,
                lastUseTime: Int64?,
                revisionTime: Int64,
                flags: Int) {
        self.itemID = itemID
        self.revision = revision
        self.contentFormatVersion = contentFormatVersion
        self.keyRotation = keyRotation
        self.content = content
        self.itemKey = itemKey
        self.state = state
        self.pinned = pinned
        self.pinTime = pinTime
        self.aliasEmail = aliasEmail
        self.createTime = createTime
        self.modifyTime = modifyTime
        self.lastUseTime = lastUseTime
        self.revisionTime = revisionTime
        self.flags = flags
    }
}

extension Item: ItemFlagable {}
