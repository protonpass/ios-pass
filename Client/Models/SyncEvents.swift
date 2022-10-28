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
    /// New or updated items
    public let updatedItems: [ItemRevision]

    /// ItemIDs deleted
    public let deletedItemIDs: [String]

    /// RotationID of the new key if there's been a key rotation
    public let newRotationID: String?

    /// New latest event ID. It can be the same as the one in the request if there are no events
    public let latestEventID: String

    /// Flag specifing if there are more events in the db and the client should request again more events
    public let eventsPending: Bool
}
