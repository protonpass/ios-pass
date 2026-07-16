//
// SecureLinkListUIModel.swift
// Proton Pass - Created on 16/07/2026.
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

public struct SecureLinkListUIModel: Identifiable, Hashable, Equatable, @unchecked Sendable {
    public var id: String {
        secureLink.id
    }

    public let secureLink: SecureLink
    public let itemContent: ItemContent
    public let url: String

    private let currentDate: Date
    private let formatter = RelativeDateTimeFormatter()

    public init(secureLink: SecureLink,
                itemContent: ItemContent,
                url: String,
                currentDate: Date = .now) {
        self.secureLink = secureLink
        self.itemContent = itemContent
        self.url = url
        self.currentDate = currentDate
    }

    public var isActive: Bool {
        secureLink.active
    }

    public var relativeTimeRemaining: String {
        let expirationDate = Date(timeIntervalSince1970: Double(secureLink.expirationTime))
        formatter.unitsStyle = .full

        return formatter.localizedString(for: expirationDate, relativeTo: currentDate)
    }
}
