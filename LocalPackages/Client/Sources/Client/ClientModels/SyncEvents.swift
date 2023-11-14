//
// SyncEvents.swift
// Proton Pass - Created on 27/10/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public struct SyncEvents: Decodable {
    /// Updated share in case the vault content changes
    public let updatedShare: Share?

    /// New or updated items
    public let updatedItems: [ItemRevision]

    /// Deleted items
    public let deletedItemIDs: [String]

    /// Items that have the last use time updated
    public let lastUseItems: [LastUseItem]

    /// New key rotation value if there has been a key rotation
    public let newKeyRotation: Int?

    /// New latest event ID. It can be the same as the one in the request if there are no events
    public let latestEventID: String

    /// If there are more events to process this will be true
    public let eventsPending: Bool

    /// If the share needs a full refresh this will be true
    /// E.g: `latestEventID` is too old
    public let fullRefresh: Bool
}
