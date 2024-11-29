//
// InviteUserToShareEndpoint.swift
// Proton Pass - Created on 11/07/2023.
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

import Entities
import Foundation
import ProtonCoreNetworking

public struct InviteUserToShareRequest: Sendable {
    /// List of keys encrypted for the other user's address key and signed with your address key
    let keys: [ItemKey]
    /// Email of the target user
    let email: String
    /// Invite target type. 1 = Vault, 2 = Item
    let targetType: Int
    /// ShareRoleID assigned to this invite
    let shareRoleId: String
    /// Invite encrypted item ID (only in case the invite is of type Item)
    let itemId: String?
    /// Expiration time for the share
    let expirationTime: Int?

    public init(keys: [ItemKey],
                email: String,
                targetType: TargetType,
                shareRole: ShareRole,
                itemId: String?,
                expirationDate: Date? = nil) {
        self.keys = keys
        self.email = email
        self.targetType = Int(targetType.rawValue)
        shareRoleId = shareRole.rawValue
        self.itemId = itemId
        if let date = expirationDate?.timeIntervalSince1970 {
            expirationTime = Int(date)
        } else {
            expirationTime = nil
        }
    }
}

extension InviteUserToShareRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case keys = "Keys"
        case email = "Email"
        case targetType = "TargetType"
        case shareRoleId = "ShareRoleID"
        case itemId = "ItemID"
        case expirationTime = "ExpirationTime"
    }
}
