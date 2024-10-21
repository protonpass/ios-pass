//
// ShareEntity.swift
// Proton Pass - Created on 18/07/2022.
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

import CoreData
import Foundation

@objc(ShareEntity)
final class ShareEntity: NSManagedObject {}

extension ShareEntity: Identifiable {}

extension ShareEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<ShareEntity> {
        NSFetchRequest<ShareEntity>(entityName: "ShareEntity")
    }

    @NSManaged var addressID: String
    @NSManaged var content: String?
    @NSManaged var contentFormatVersion: Int64
    @NSManaged var contentKeyRotation: Int64
    @NSManaged var createTime: Int64
    @NSManaged var expireTime: Int64
    @NSManaged var owner: Bool
    @NSManaged var permission: Int64
    @NSManaged var shareID: String
    @NSManaged var symmetricallyEncryptedContent: String?
    @NSManaged var targetID: String
    @NSManaged var targetType: Int64
    @NSManaged var vaultID: String
    @NSManaged var userID: String
    @NSManaged var shareRoleID: String
    @NSManaged var targetMembers: Int64
    @NSManaged var targetMaxMembers: Int64
    @NSManaged var pendingInvites: Int64
    @NSManaged var newUserInvitesReady: Int64
    @NSManaged var shared: Bool
    @NSManaged var canAutoFill: Bool
}

extension ShareEntity {
    func toSymmetricallyEncryptedShare() -> SymmetricallyEncryptedShare {
        .init(encryptedContent: symmetricallyEncryptedContent,
              share: .init(shareID: shareID,
                           vaultID: vaultID,
                           addressID: addressID,
                           targetType: targetType,
                           targetID: targetID,
                           permission: permission,
                           shareRoleID: shareRoleID,
                           targetMembers: targetMembers,
                           targetMaxMembers: targetMaxMembers,
                           pendingInvites: pendingInvites,
                           newUserInvitesReady: newUserInvitesReady,
                           owner: owner,
                           shared: shared,
                           content: content,
                           contentKeyRotation: contentKeyRotation == -1 ? nil : contentKeyRotation,
                           contentFormatVersion: contentFormatVersion == -1 ? nil : contentFormatVersion,
                           expireTime: expireTime == -1 ? nil : expireTime,
                           createTime: createTime,
                           canAutoFill: canAutoFill))
    }

    func hydrate(from symmetricallyEncryptedShare: SymmetricallyEncryptedShare, userId: String) {
        let share = symmetricallyEncryptedShare.share
        content = share.content
        contentFormatVersion = share.contentFormatVersion ?? -1
        contentKeyRotation = share.contentKeyRotation ?? -1
        createTime = share.createTime
        expireTime = share.expireTime ?? -1
        owner = share.owner
        permission = share.permission
        shareID = share.shareID
        symmetricallyEncryptedContent = symmetricallyEncryptedShare.encryptedContent
        targetID = share.targetID
        targetType = share.targetType
        vaultID = share.vaultID
        addressID = share.addressID
        userID = userId
        shareRoleID = share.shareRoleID
        targetMembers = share.targetMembers
        targetMaxMembers = share.targetMaxMembers
        pendingInvites = share.pendingInvites
        newUserInvitesReady = share.newUserInvitesReady
        shared = share.shared
        canAutoFill = share.canAutoFill
    }
}
