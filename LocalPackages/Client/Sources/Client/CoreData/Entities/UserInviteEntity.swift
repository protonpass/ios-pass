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
    @NSManaged var vaultData: VaultDataEntity?
    @NSManaged var keys: Set<InviteKeyEntity>
}

extension UserInviteEntity {
    var toUserInvite: UserInvite {
        .init(inviteToken: inviteToken,
              remindersSent: Int(remindersSent),
              targetType: Int(targetType),
              targetID: targetID,
              inviterEmail: inviterEmail,
              invitedEmail: invitedEmail,
              invitedAddressID: invitedAddressID.nilIfEmpty,
              keys: keys.map(\.toInviteKey),
              vaultData: vaultData?.toVaultData,
              fromNewUser: fromNewUser,
              createTime: Int(createTime))
    }

    func hydrate(userID: String, invite: UserInvite, context: NSManagedObjectContext) {
        let context = managedObjectContext ?? context
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

        // Create "vaultData" relationship
        if let vaultData {
            context.delete(vaultData)
        }

        if let vaultData = invite.vaultData {
            let entity = VaultDataEntity(context: context)
            entity.hydrate(with: vaultData)
            entity.invite = self
            self.vaultData = entity
        }

        // Create "keys" relationship
        for key in keys {
            context.delete(key)
        }

        var newKeys = Set<InviteKeyEntity>()
        for key in invite.keys {
            let entity = InviteKeyEntity(context: context)
            entity.hydrate(with: key)
            entity.invite = self
            newKeys.insert(entity)
        }
        keys = newKeys
    }
}
