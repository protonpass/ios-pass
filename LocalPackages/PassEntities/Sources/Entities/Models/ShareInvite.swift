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

// MARK: - Invite

public struct ShareInvite: Codable {
    public let inviteID, invitedEmail, inviterEmail: String
    public let targetType: Int
    public let targetID: String
    public let remindersSent, createTime, modifyTime: Int

    public init(inviteID: String,
                invitedEmail: String,
                inviterEmail: String,
                targetType: Int,
                targetID: String,
                remindersSent: Int,
                createTime: Int,
                modifyTime: Int) {
        self.inviteID = inviteID
        self.invitedEmail = invitedEmail
        self.inviterEmail = inviterEmail
        self.targetType = targetType
        self.targetID = targetID
        self.remindersSent = remindersSent
        self.createTime = createTime
        self.modifyTime = modifyTime
    }

    enum CodingKeys: String, CodingKey {
        case inviteID = "InviteID"
        case invitedEmail = "InvitedEmail"
        case inviterEmail = "InviterEmail"
        case targetType = "TargetType"
        case targetID = "TargetID"
        case remindersSent = "RemindersSent"
        case createTime = "CreateTime"
        case modifyTime = "ModifyTime"
    }
}
