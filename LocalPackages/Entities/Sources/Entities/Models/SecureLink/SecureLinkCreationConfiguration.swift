//
// SecureLinkCreationConfiguration.swift
// Proton Pass - Created on 16/05/2024.
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

import Foundation

public struct SecureLinkCreationConfiguration: Decodable, Equatable, Sendable {
    public let shareId: String
    public let itemId: String
    public let revision: Int
    public let expirationTime: Int
    public let encryptedItemKey: String
    public let maxReadCount: Int?
    public let encryptedLinkKey: String
    public let linkKeyShareKeyRotation: Int64
    public let linkKeyEncryptedWithItemKey: Bool

    public init(shareId: String,
                itemId: String,
                revision: Int,
                expirationTime: Int,
                encryptedItemKey: String,
                maxReadCount: Int?,
                encryptedLinkKey: String,
                linkKeyShareKeyRotation: Int64,
                linkKeyEncryptedWithItemKey: Bool) {
        self.shareId = shareId
        self.itemId = itemId
        self.revision = revision
        self.expirationTime = expirationTime
        self.encryptedItemKey = encryptedItemKey
        self.maxReadCount = maxReadCount
        self.encryptedLinkKey = encryptedLinkKey
        self.linkKeyShareKeyRotation = linkKeyShareKeyRotation
        self.linkKeyEncryptedWithItemKey = linkKeyEncryptedWithItemKey
    }
}
