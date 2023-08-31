//
// SearchEntry.swift
// Proton Pass - Created on 16/03/2023.
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

public struct SearchEntry: Hashable, Sendable {
    public let itemID: String
    public let shareID: String
    public let time: Int64

    public init(itemID: String, shareID: String, time: Int64) {
        self.itemID = itemID
        self.shareID = shareID
        self.time = time
    }

    public init(item: ItemIdentifiable, date: Date = .now) {
        itemID = item.itemId
        shareID = item.shareId
        time = Int64(date.timeIntervalSince1970)
    }
}

extension SearchEntry: ItemIdentifiable {
    public var shareId: String { shareID }
    public var itemId: String { itemID }
}
