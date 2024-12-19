//
// ShareInvites.swift
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

public struct ShareInvites: Equatable, Sendable {
    public let existingUserInvites: [ShareExistingUserInvite]
    public let newUserInvites: [ShareNewUserInvite]

    public init(existingUserInvites: [ShareExistingUserInvite],
                newUserInvites: [ShareNewUserInvite]) {
        self.existingUserInvites = existingUserInvites
        self.newUserInvites = newUserInvites
    }

    public static var `default`: Self {
        .init(existingUserInvites: [], newUserInvites: [])
    }

    public var isEmpty: Bool {
        existingUserInvites.isEmpty && newUserInvites.isEmpty
    }

    public var totalNumberOfInvites: Int {
        existingUserInvites.count + newUserInvites.count
    }
}

public struct ShareExistingUserInvite: Decodable, Equatable, Identifiable, Sendable {
    public let inviteID, invitedEmail, inviterEmail, shareRoleID: String
    public let targetType: Int
    public let targetID: String
    public let remindersSent, createTime, modifyTime: Int

    public var shareType: TargetType {
        .init(rawValue: targetType) ?? .unknown
    }

    public var shareRole: ShareRole {
        .init(rawValue: shareRoleID) ?? .read
    }

    public var id: String {
        inviteID
    }

    public init(inviteID: String,
                invitedEmail: String,
                inviterEmail: String,
                shareRoleID: String,
                targetType: Int,
                targetID: String,
                remindersSent: Int,
                createTime: Int,
                modifyTime: Int) {
        self.inviteID = inviteID
        self.invitedEmail = invitedEmail
        self.inviterEmail = inviterEmail
        self.shareRoleID = shareRoleID
        self.targetType = targetType
        self.targetID = targetID
        self.remindersSent = remindersSent
        self.createTime = createTime
        self.modifyTime = modifyTime
    }
}

public enum NewShareInviteState: Sendable {
    case waitingForAccountCreation
    case accountCreated
}

public struct ShareNewUserInvite: Decodable, Equatable, Identifiable, Sendable {
    public let newUserInviteID: String
    public let state: Int
    public let targetType: Int
    public let targetID: String
    public let shareRoleID: String
    public let invitedEmail: String
    public let inviterEmail: String
    public let signature: String
    public let createTime: Int
    public let modifyTime: Int

    public var shareType: TargetType {
        .init(rawValue: targetType) ?? .unknown
    }

    public var shareRole: ShareRole {
        .init(rawValue: shareRoleID) ?? .read
    }

    public var id: String {
        newUserInviteID
    }

    public var inviteState: NewShareInviteState {
        if state == 1 {
            .waitingForAccountCreation
        } else {
            .accountCreated
        }
    }

    public init(newUserInviteID: String,
                state: Int,
                targetType: Int,
                targetID: String,
                shareRoleID: String,
                invitedEmail: String,
                inviterEmail: String,
                signature: String,
                createTime: Int,
                modifyTime: Int) {
        self.newUserInviteID = newUserInviteID
        self.state = state
        self.targetType = targetType
        self.targetID = targetID
        self.shareRoleID = shareRoleID
        self.invitedEmail = invitedEmail
        self.inviterEmail = inviterEmail
        self.signature = signature
        self.createTime = createTime
        self.modifyTime = modifyTime
    }
}
