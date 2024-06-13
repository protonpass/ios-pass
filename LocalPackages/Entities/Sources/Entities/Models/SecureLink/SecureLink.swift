//
// SecureLink.swift
// Proton Pass - Created on 15/05/2024.
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

public struct SecureLink: Decodable, Equatable, Sendable, Identifiable, Hashable {
    public let linkID: String
    public let readCount, maxReadCount: Int?
    public let expirationTime: Int
    public let shareID, itemID: String
    public let linkURL: String
    public let encryptedLinkKey: String
    public let linkKeyShareKeyRotation: Int64

    public var id: String {
        linkID
    }
}

public struct SecureLinkListUIModel: Identifiable, Hashable, Equatable, Sendable {
    public var id: String {
        secureLink.id
    }

    public let secureLink: SecureLink
    public let itemContent: ItemContent
    public let url: String

    public init(secureLink: SecureLink, itemContent: ItemContent, url: String) {
        self.secureLink = secureLink
        self.itemContent = itemContent
        self.url = url
    }

    public var relativeTimeRemaining: String {
        let expirationDate = Date(timeIntervalSince1970: Double(secureLink.expirationTime))
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        let currentDate = Date()
        let relativeTime = formatter.localizedString(for: expirationDate, relativeTo: currentDate)

        return relativeTime
    }
}

public struct SecureLinkKeys {
    public let linkKey: String
    public let itemKeyEncoded: String
    public let linkKeyEncoded: String
    public let shareKeyRotation: Int64

    public init(linkKey: String, itemKeyEncoded: String, linkKeyEncoded: String, shareKeyRotation: Int64) {
        self.linkKey = linkKey
        self.itemKeyEncoded = itemKeyEncoded
        self.linkKeyEncoded = linkKeyEncoded
        self.shareKeyRotation = shareKeyRotation
    }
}
