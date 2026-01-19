//
// GroupInvite.swift
// Proton Pass - Created on 30/07/2025.
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

import Foundation

public struct GroupInvite: Decodable, Hashable, Equatable, Identifiable, Sendable {
    public let inviteID: String
    public let inviterUserID: String
    public let inviterEmail: String
    public let invitedGroupID: String
    public let invitedEmail: String
    public let targetType: Int
    public let targetID: String
    public let remindersSent: Int
    public let inviteToken: String
    public let invitedAddressID: String
    public let keys: [InviteKey]
    public let vaultData: VaultData?
    public let data: String?
    public let isGroupOwner: Bool
    public let createTime: Int

    public var id: String {
        inviteID
    }

    public init(inviteID: String,
                inviterUserID: String,
                inviterEmail: String,
                invitedGroupID: String,
                invitedEmail: String,
                targetType: Int,
                targetID: String,
                remindersSent: Int,
                inviteToken: String,
                invitedAddressID: String,
                keys: [ItemKey],
                vaultData: VaultData?,
                data: String?,
                isGroupOwner: Bool,
                createTime: Int) {
        self.inviteID = inviteID
        self.inviterUserID = inviterUserID
        self.inviterEmail = inviterEmail
        self.invitedGroupID = invitedGroupID
        self.invitedEmail = invitedEmail
        self.targetType = targetType
        self.targetID = targetID
        self.remindersSent = remindersSent
        self.inviteToken = inviteToken
        self.invitedAddressID = invitedAddressID
        self.keys = keys
        self.vaultData = vaultData
        self.data = data
        self.isGroupOwner = isGroupOwner
        self.createTime = createTime
    }
}
