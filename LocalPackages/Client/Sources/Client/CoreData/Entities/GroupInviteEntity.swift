//
// GroupInviteEntity.swift
// Proton Pass - Created on 25/09/2025.
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

@objc(GroupInviteEntity)
final class GroupInviteEntity: NSManagedObject {}

extension GroupInviteEntity: Identifiable {}

extension GroupInviteEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<GroupInviteEntity> {
        NSFetchRequest<GroupInviteEntity>(entityName: "GroupInviteEntity")
    }

    @NSManaged var userID: String
    @NSManaged var inviteID: String
    @NSManaged var inviterUserID: String
    @NSManaged var inviterEmail: String
    @NSManaged var invitedGroupID: String
    @NSManaged var invitedEmail: String
    @NSManaged var targetType: Int64
    @NSManaged var targetID: String
    @NSManaged var remindersSent: Int64
    @NSManaged var inviteToken: String
    @NSManaged var invitedAddressID: String
    @NSManaged var data: String?
    @NSManaged var createTime: Int64
    @NSManaged var vaultData: VaultDataEntity?
    @NSManaged var keys: Set<InviteKeyEntity>
}

extension GroupInviteEntity {
    var toGroupInvite: GroupInvite {
        GroupInvite(inviteID: inviteID,
                    inviterUserID: inviterUserID,
                    inviterEmail: inviterEmail,
                    invitedGroupID: invitedGroupID,
                    invitedEmail: invitedEmail,
                    targetType: Int(targetType),
                    targetID: targetID,
                    remindersSent: Int(remindersSent),
                    inviteToken: inviteToken,
                    invitedAddressID: invitedAddressID,
                    keys: keys.map(\.toInviteKey),
                    vaultData: vaultData?.toVaultData,
                    data: data,
                    createTime: Int(createTime))
    }

    func hydrate(userID: String, invite: GroupInvite, context: NSManagedObjectContext) {
        let context = managedObjectContext ?? context
        self.userID = userID
        inviteID = invite.inviteID
        inviterUserID = invite.inviterUserID
        inviterEmail = invite.inviterEmail
        invitedGroupID = invite.invitedGroupID
        invitedEmail = invite.invitedEmail
        targetType = Int64(invite.targetType)
        targetID = invite.targetID
        remindersSent = Int64(invite.remindersSent)
        inviteToken = invite.inviteToken
        invitedAddressID = invite.invitedAddressID
        data = invite.data
        createTime = Int64(invite.createTime)

        if let existingVaultData = vaultData, let newVaultData = invite.vaultData {
            // Update existing
            existingVaultData.hydrate(with: newVaultData)
        } else if let newVaultData = invite.vaultData {
            // Create new
            let entity = VaultDataEntity(context: context)
            entity.hydrate(with: newVaultData)
            entity.groupInvite = self
            vaultData = entity
        }

        // Create "keys" relationship
        for key in keys {
            context.delete(key)
        }

        var newKeys = Set<InviteKeyEntity>()
        for key in invite.keys {
            let entity = InviteKeyEntity(context: context)
            entity.hydrate(with: key)
            entity.groupInvite = self
            newKeys.insert(entity)
        }
        keys = newKeys
    }
}
