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
public struct SymmetricallyEncryptedItem: Equatable, Sendable {
    /// ID of the share that the item belongs to
    public let shareId: String

    /// Original item revision object as returned by the server
    public let item: ItemRevision

    /// Symmetrically encrypted content in base 64 format
    public let encryptedContent: String

    /// Whether the item is type log in or not
    public let isLogInItem: Bool

    public init(shareId: String, item: ItemRevision, encryptedContent: String, isLogInItem: Bool) {
        self.shareId = shareId
        self.item = item
        self.encryptedContent = encryptedContent
        self.isLogInItem = isLogInItem
    }
}
