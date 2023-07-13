//
//  UserInvite.swift
//
//
//  Created by martin on 13/07/2023.
//

import Foundation

// MARK: - User Invite

public struct UserInvite: Codable {
    public let inviteID: String
    public let remindersSent: Int
    public let targetType: Int
    public let targetID, inviterEmail, invitedEmail: String
    public let keys: [ItemKey]
    public let createTime: Int

    enum CodingKeys: String, CodingKey {
        case inviteID = "InviteID"
        case remindersSent = "RemindersSent"
        case targetType = "TargetType"
        case targetID = "TargetID"
        case inviterEmail = "InviterEmail"
        case invitedEmail = "InvitedEmail"
        case keys = "Keys"
        case createTime = "CreateTime"
    }
}
