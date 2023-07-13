//
// GetPendingInvitesforShareEndpoint.swift
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

import ProtonCore_Networking
import ProtonCore_Services

public struct GetPendingInvitesforShareResponse: Decodable {
    let code: Int
    let invites: [ShareInvite]
}

public struct GetPendingInvitesforShareEndpoint: Endpoint {
    public typealias Body = EmptyRequest
    public typealias Response = GetPendingInvitesforShareResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod

    public init(for shareId: String) {
        debugDescription = "Get pending invites for share"
        path = "/pass/v1/share/\(shareId)/invite"
        method = .get
    }
}

// MARK: - Invite

struct ShareInvite: Codable {
    let inviteID, invitedEmail, inviterEmail: String
    let targetType: Int
    let targetID: String
    let remindersSent, createTime, modifyTime: Int

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
