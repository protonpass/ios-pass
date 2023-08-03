//
//
// GetAllUsersForShare.swift
// Proton Pass - Created on 03/08/2023.
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
//

import Entities

protocol GetAllUsersForShareUseCase: Sendable {
    func execute(with shareId: String) async throws -> [ShareUser]
}

extension GetAllUsersForShareUseCase {
    func callAsFunction(with shareId: String) async throws -> [ShareUser] {
        try await execute(with: shareId)
    }
}

final class GetAllUsersForShare: GetAllUsersForShareUseCase {
    private let getUsersLinkedToShare: GetUsersLinkedToShareUseCase
    private let getPendingInvitationsForShare: GetPendingInvitationsForShareUseCase

    init(getUsersLinkedToShare: GetUsersLinkedToShareUseCase,
         getPendingInvitationsForShare: GetPendingInvitationsForShareUseCase) {
        self.getUsersLinkedToShare = getUsersLinkedToShare
        self.getPendingInvitationsForShare = getPendingInvitationsForShare
    }

    func execute(with shareId: String) async throws -> [ShareUser] {
        async let pendingShareUsers = getPendingInvitationsForShare(with: shareId).map(\.toShareUser)
        async let shareUsers = getUsersLinkedToShare(with: shareId).map(\.toShareUser)
        let totalUser = try await [pendingShareUsers, shareUsers].flatMap { $0 }
        return totalUser
    }
}

struct ShareUser: Equatable, Hashable {
    let email: String
    let shareRole: ShareRole?
    let inviteID: String?
    let shareID: String?
    let userName: String?
}

extension UserShareInfos {
    var toShareUser: ShareUser {
        ShareUser(email: userEmail,
                  shareRole: shareRole,
                  inviteID: nil,
                  shareID: shareID,
                  userName: userName)
    }
}

extension ShareInvite {
    var toShareUser: ShareUser {
        ShareUser(email: invitedEmail,
                  shareRole: nil,
                  inviteID: inviteID,
                  shareID: nil,
                  userName: nil)
    }
}

// public struct UserShareInfos: Codable, Hashable {
//    public let shareID: String
//    public let userName: String
//    public let userEmail: String
//    public let targetType: Int
//    public let targetID: String
//    public let permission: Int
//    public let shareRoleID: String
//    public let expireTime: Int?
//    public let createTime: Int?
//
//    public var shareRole: ShareRole {
//        .init(rawValue: shareRoleID) ?? .read
//    }
// }
//
//
// public struct ShareInvite: Codable {
//    public let inviteID,
//    public let invitedEmail: String
//    public let inviterEmail: String
//    public let targetType: Int
//    public let targetID: String
//    public let remindersSent, createTime, modifyTime: Int
//
//    public var shareType: TargetType {
//        .init(rawValue: Int64(targetType)) ?? .unknown
//    }
// }
