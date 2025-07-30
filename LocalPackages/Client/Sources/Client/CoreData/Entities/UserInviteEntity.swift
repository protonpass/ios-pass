//
// UserInviteEntity.swift
// Proton Pass - Created on 29/07/2025.
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

import CoreData
import Entities

@objc(UserInviteEntity)
final class UserInviteEntity: NSManagedObject {}

extension UserInviteEntity: Identifiable {}

extension UserInviteEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<UserInviteEntity> {
        NSFetchRequest<UserInviteEntity>(entityName: "UserInviteEntity")
    }

    @NSManaged var userID: String
    @NSManaged var createTime: Int64
    @NSManaged var fromNewUser: Bool
    @NSManaged var invitedAddressID: String
    @NSManaged var invitedEmail: String
    @NSManaged var inviterEmail: String
    @NSManaged var inviteToken: String
    @NSManaged var remindersSent: Int64
    @NSManaged var targetID: String
    @NSManaged var targetType: Int64
    @NSManaged var vaultDataContent: String
    @NSManaged var vaultDataContentFormatVersion: Int64
    @NSManaged var vaultDataContentKeyRotation: Int64
    @NSManaged var vaultDataMemberCount: Int64
    @NSManaged var vaultDataItemCount: Int64
}

extension UserInviteEntity {
    /// We could only retrieve a part of `UserInvite` because keys are stored in another table
    var toPartialUserInvite: UserInvite {
        let vaultData: VaultData? = if !vaultDataContent.isEmpty,
                                       vaultDataContentFormatVersion != -1,
                                       vaultDataContentKeyRotation != -1,
                                       vaultDataMemberCount != -1,
                                       vaultDataItemCount != -1 {
            .init(content: vaultDataContent,
                  contentKeyRotation: Int(vaultDataContentKeyRotation),
                  contentFormatVersion: Int(vaultDataContentFormatVersion),
                  memberCount: Int(vaultDataMemberCount),
                  itemCount: Int(vaultDataItemCount))
        } else {
            nil
        }

        return .init(inviteToken: inviteToken,
                     remindersSent: Int(remindersSent),
                     targetType: Int(targetType),
                     targetID: targetID,
                     inviterEmail: inviterEmail,
                     invitedEmail: invitedEmail,
                     invitedAddressID: invitedAddressID.nilIfEmpty,
                     keys: [], // stored in InviteKeyEntity
                     vaultData: vaultData,
                     fromNewUser: fromNewUser,
                     createTime: Int(createTime))
    }

    func hydrate(userID: String, invite: UserInvite) {
        self.userID = userID
        createTime = Int64(invite.createTime)
        fromNewUser = invite.fromNewUser
        invitedAddressID = invite.invitedAddressID ?? ""
        invitedEmail = invite.invitedEmail
        inviterEmail = invite.inviterEmail
        inviteToken = invite.inviteToken
        remindersSent = Int64(invite.remindersSent)
        targetID = invite.targetID
        targetType = Int64(invite.targetType)

        let vaultData = invite.vaultData
        vaultDataContent = vaultData?.content ?? ""
        vaultDataContentFormatVersion = Int64(vaultData?.contentFormatVersion ?? -1)
        vaultDataContentKeyRotation = Int64(vaultData?.contentKeyRotation ?? -1)
        vaultDataMemberCount = Int64(vaultData?.memberCount ?? -1)
        vaultDataItemCount = Int64(vaultData?.itemCount ?? -1)
    }
}
