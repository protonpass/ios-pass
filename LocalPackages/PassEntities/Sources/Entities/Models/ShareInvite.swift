//
//  ShareInvite.swift
//
//
//  Created by martin on 13/07/2023.
//

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
