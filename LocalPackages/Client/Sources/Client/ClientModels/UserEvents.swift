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
    public let sharesToGetInvites: [UserEventShare]
    public let sharesWithInvitesToCreate: [UserEventShare]
    public let planChanged: Bool
    public let eventsPending: Bool
    public let fullRefresh: Bool

    public init(lastEventID: String,
                itemsUpdated: [UserEventItem],
                itemsDeleted: [UserEventItem],
                sharesUpdated: [UserEventShare],
                sharesDeleted: [UserEventShare],
                sharesToGetInvites: [UserEventShare],
                sharesWithInvitesToCreate: [UserEventShare],
                planChanged: Bool,
                eventsPending: Bool,
                fullRefresh: Bool) {
        self.lastEventID = lastEventID
        self.itemsUpdated = itemsUpdated
        self.itemsDeleted = itemsDeleted
        self.sharesUpdated = sharesUpdated
        self.sharesDeleted = sharesDeleted
        self.sharesToGetInvites = sharesToGetInvites
        self.sharesWithInvitesToCreate = sharesWithInvitesToCreate
        self.planChanged = planChanged
        self.eventsPending = eventsPending
        self.fullRefresh = fullRefresh
    }

    /// Reflect the least changes in user's data in order to locally reload everything
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

    public init(shareID: String, itemID: String, eventToken: String) {
        self.shareID = shareID
        self.itemID = itemID
        self.eventToken = eventToken
    }
}

public struct UserEventShare: Sendable, Decodable, Equatable {
    public let shareID: String
    public let eventToken: String

    public init(shareID: String, eventToken: String) {
        self.shareID = shareID
        self.eventToken = eventToken
    }
}
