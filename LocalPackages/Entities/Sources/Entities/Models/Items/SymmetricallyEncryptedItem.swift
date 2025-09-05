//
// SymmetricallyEncryptedItem.swift
// Proton Pass - Created on 24/11/2023.
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

/// ItemRevision with its symmetrically encrypted content by an application-wide symmetric key
public struct SymmetricallyEncryptedItem: Equatable, ItemIdentifiable, Sendable, Hashable {
    /// ID of the share that the item belongs to
    public let shareId: String

    public var itemId: String { item.itemID }

    public var userId: String

    /// Original item revision object as returned by the server
    public let item: Item

    /// Symmetrically encrypted content in base 64 format
    public let encryptedContent: String

    /// Whether the item is type log in or not
    public let isLogInItem: Bool

    /// Only applicable to aliases
    public let encryptedSimpleLoginNote: String?

    // Only applicable to aliases
    public let simpleLoginNoteSynced: Bool

    public init(shareId: String,
                userId: String,
                item: Item,
                encryptedContent: String,
                isLogInItem: Bool,
                encryptedSimpleLoginNote: String?,
                simpleLoginNoteSynced: Bool) {
        self.shareId = shareId
        self.item = item
        self.userId = userId
        self.encryptedContent = encryptedContent
        self.isLogInItem = isLogInItem
        self.encryptedSimpleLoginNote = encryptedSimpleLoginNote
        self.simpleLoginNoteSynced = simpleLoginNoteSynced
    }
}
