//
// Alias.swift
// Proton Pass - Created on 15/09/2022.
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

// MARK: - User Invite

public struct UserInvite: Decodable, Hashable, Equatable, Identifiable {
    public let inviteToken: String
    public let remindersSent: Int
    public let targetType: Int
    public let targetID, inviterEmail, invitedEmail: String
    /// Share keys encrypted for the address key of the invitee and signed with the user keys of the inviter
    public let keys: [ItemKey]
    public let vaultData: VaultData?
    public let createTime: Int

    public var id: String {
        inviteToken
    }

    public var inviteType: TargetType {
        .init(rawValue: Int64(targetType)) ?? .unknown
    }

    public init(inviteToken: String,
                remindersSent: Int,
                targetType: Int,
                targetID: String,
                inviterEmail: String,
                invitedEmail: String,
                keys: [ItemKey],
                vaultData: VaultData?,
                createTime: Int) {
        self.inviteToken = inviteToken
        self.remindersSent = remindersSent
        self.targetType = targetType
        self.targetID = targetID
        self.inviterEmail = inviterEmail
        self.invitedEmail = invitedEmail
        self.keys = keys
        self.vaultData = vaultData
        self.createTime = createTime
    }
}

public extension UserInvite {
    static var mocked: UserInvite {
        UserInvite(inviteToken: "12345789",
                   remindersSent: 1,
                   targetType: 1,
                   targetID: "id",
                   inviterEmail: "inviterEmail@test.com",
                   invitedEmail: "invitedEmail@test.com",
                   keys: [],
                   vaultData: VaultData.mocked,
                   createTime: 1)
    }
}
