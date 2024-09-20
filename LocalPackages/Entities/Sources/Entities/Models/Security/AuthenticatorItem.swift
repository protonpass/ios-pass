//
// AuthenticatorItem.swift
// Proton Pass - Created on 19/03/2024.
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

public struct AuthenticatorItem: Sendable, Identifiable, Equatable {
    public let itemId: String
    public let shareId: String
    public let icon: ItemThumbnailData
    public let title: String
    public let uri: String

    public var id: String {
        "\(itemId + shareId)"
    }

    public init(itemId: String, shareId: String, icon: ItemThumbnailData, title: String, uri: String) {
        self.itemId = itemId
        self.shareId = shareId
        self.icon = icon
        self.title = title
        self.uri = uri
    }
}
