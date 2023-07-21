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

public struct UserInvite: Decodable {
    public let inviteToken: String
    public let remindersSent: Int
    public let targetType: Int
    public let targetID, inviterEmail, invitedEmail: String
    /// Share keys encrypted for the address key of the invitee and signed with the user keys of the inviter
    public let keys: [ItemKey]
    public let vaultData: VaultData?
    public let createTime: Int

    enum CodingKeys: String, CodingKey {
        case inviteToken = "InviteToken"
        case remindersSent = "RemindersSent"
        case targetType = "TargetType"
        case targetID = "TargetID"
        case inviterEmail = "InviterEmail"
        case invitedEmail = "InvitedEmail"
        case keys = "Keys"
        case vaultData = "VaultData"
        case createTime = "CreateTime"
    }

    public var inviteType: TargetType {
        .init(rawValue: Int64(targetType)) ?? .unknown
    }
}
