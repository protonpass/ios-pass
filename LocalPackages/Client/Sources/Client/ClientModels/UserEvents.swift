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
    public let itemsUpdated: [ItemEvent]
    public let itemsDeleted: [ItemEvent]
    public let aliasNoteChanged: [ItemEvent]
    public let invitesChanged: ChangeEvent?
    public let groupInvitesChanged: ChangeEvent?
    public let sharesCreated: [ShareEvent]
    public let sharesUpdated: [ShareEvent]
    public let sharesDeleted: [ShareEvent]
    public let sharesWithInvitesToCreate: [ShareEvent]
    public let foldersUpdated: [FolderEvent]
    public let foldersDeleted: [FolderEvent]
    public let pendingAliasToCreateChanged: ChangeEvent?
    public let breachUpdate: ChangeEvent?
    public let organizationUpdate: ChangeEvent?
    public let refreshUser: Bool
    public let eventsPending: Bool
    public let fullRefresh: Bool

    /// Reflect the fact that some changes occurred to user's data and that we need to reload it locally
    public var dataUpdated: Bool {
        !itemsUpdated.isEmpty ||
            !itemsDeleted.isEmpty ||
            !aliasNoteChanged.isEmpty ||
            !sharesCreated.isEmpty ||
            !sharesUpdated.isEmpty ||
            !sharesDeleted.isEmpty ||
            !sharesWithInvitesToCreate.isEmpty ||
            !foldersUpdated.isEmpty ||
            !foldersDeleted.isEmpty ||
            pendingAliasToCreateChanged != nil
    }
}

public struct ItemEvent: Sendable, Decodable, Equatable, ItemIdentifiable {
    public let shareID: String
    public let itemID: String
    public let eventToken: String

    /// Seemingly redundant but we need to keep `shareID` and `itemID`
    /// with capitalized D in order to not break the decoding process
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

public struct ChangeEvent: Sendable, Decodable, Equatable {
    public let eventToken: String
}

public struct FolderEvent: Sendable, Decodable, Equatable, ElementIdentifiable {
    public let shareID: String
    public let folderID: String
    public let eventToken: String

    // Seemingly redundant but we need to keep `shareID` and `itemID`
    // with capitalized D in order to not break the decoding process

    public var shareId: String {
        shareID
    }

    // periphery:ignore
    public var folderId: String {
        folderID
    }

    public var elementId: String {
        folderID
    }
}
