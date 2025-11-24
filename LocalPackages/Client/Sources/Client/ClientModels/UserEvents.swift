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

// Remove later
// periphery:ignore:all
import Entities
import Foundation

public struct UserEvents: Sendable, Decodable {
    public let lastEventID: String
    public let itemsUpdated: [ItemEvent]
    public let itemsDeleted: [ItemEvent]
    public let aliasNoteChanged: [ItemEvent]
    public let invitesChanged: InviteChangeEvent?
    public let groupInvitesChanged: InviteChangeEvent?
    //    public let sharesCreated: [UserEventShare]
    public let sharesUpdated: [ShareEvent]
    public let sharesDeleted: [ShareEvent]
    public let sharesWithInvitesToCreate: [ShareEvent]
    public let foldersUpdated: [FolderEvent]
    public let foldersDeleted: [FolderEvent]
    public let planChanged: Bool
    public let eventsPending: Bool
    public let fullRefresh: Bool

    /// Reflect the fact that some changes occurred to user's data and that we need to reload it locally
    public var dataUpdated: Bool {
        !itemsUpdated.isEmpty ||
            !itemsDeleted.isEmpty ||
            !aliasNoteChanged.isEmpty ||
            !sharesUpdated.isEmpty ||
            !sharesDeleted.isEmpty ||
            !sharesWithInvitesToCreate.isEmpty ||
            !foldersUpdated.isEmpty ||
            !foldersDeleted.isEmpty
    }
}

public struct ItemEvent: Sendable, Decodable, Equatable, ItemIdentifiable {
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

public struct ShareEvent: Sendable, Decodable, Equatable {
    public let shareID: String
    public let eventToken: String
}

public struct InviteChangeEvent: Sendable, Decodable, Equatable {
    public let eventToken: String
}

public struct FolderEvent: Sendable, Decodable, Equatable {
    public let shareID: String
    public let folderID: String
    public let eventToken: String

    // Seemingly redundant but we need to keep `shareID` and `itemID`
    // with capitalized D in order to not break the decoding process
    public var shareId: String {
        shareID
    }

    public var folderId: String {
        folderID
    }
}
