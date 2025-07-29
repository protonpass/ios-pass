//
// UserEvents.swift
// Proton Pass - Created on 15/05/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Entities
import Foundation

public struct UserEvents: Sendable, Decodable {
    public let lastEventID: String
    public let itemsUpdated: [UserEventItem]
    public let itemsDeleted: [UserEventItem]
    public let sharesUpdated: [UserEventShare]
    public let sharesDeleted: [UserEventShare]
    public let planChanged: Bool
    public let eventsPending: Bool
    public let fullRefresh: Bool

    /// Reflect the fact that some changes occurred to user's data and that we need to reload it locally
    public var dataUpdated: Bool {
        !itemsUpdated.isEmpty ||
            !itemsDeleted.isEmpty ||
            !sharesUpdated.isEmpty ||
            !sharesDeleted.isEmpty
    }
}

public struct UserEventItem: Sendable, Decodable, Equatable, ItemIdentifiable {
    public let shareID: String
    public let itemID: String
    public let eventToken: String

    // Seemingly redundant but we need to keep `shareID` and `itemID`
    // with capitalized D in order to not break the decoding process
    public var shareId: String {
        shareID
    }

    public var itemId: String {
        itemID
    }
}

public struct UserEventShare: Sendable, Decodable, Equatable {
    public let shareID: String
    public let eventToken: String
}
