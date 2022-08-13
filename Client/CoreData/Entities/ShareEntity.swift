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
public final class ShareEntity: NSManagedObject {}

extension ShareEntity: Identifiable {}

extension ShareEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<ShareEntity> {
        NSFetchRequest<ShareEntity>(entityName: "ShareEntity")
    }

    @NSManaged var acceptanceSignature: String?
    @NSManaged var content: String?
    @NSManaged var contentEncryptedAddressSignature: String?
    @NSManaged var contentEncryptedVaultSignature: String?
    @NSManaged var contentFormatVersion: Int16
    @NSManaged var contentRotationID: String?
    @NSManaged var contentSignatureEmail: String?
    @NSManaged var createTime: Int64
    @NSManaged var expireTime: Int64
    @NSManaged var inviterAcceptanceSignature: String?
    @NSManaged var inviterEmail: String?
    @NSManaged var permission: Int16
    @NSManaged var shareID: String?
    @NSManaged var signingKey: String?
    @NSManaged var signingKeyPassphrase: String?
    @NSManaged var targetID: String?
    @NSManaged var targetType: Int16
    @NSManaged var userID: String?
    @NSManaged var vaultID: String?
    @NSManaged var itemKeys: NSSet?
    @NSManaged var vaultKeys: NSSet?
}

// MARK: Generated accessors for itemKeys
extension ShareEntity {
    @objc(addItemKeysObject:)
    @NSManaged func addToItemKeys(_ value: ItemKeyEntity)

    @objc(removeItemKeysObject:)
    @NSManaged func removeFromItemKeys(_ value: ItemKeyEntity)

    @objc(addItemKeys:)
    @NSManaged func addToItemKeys(_ values: NSSet)

    @objc(removeItemKeys:)
    @NSManaged func removeFromItemKeys(_ values: NSSet)
}

// MARK: Generated accessors for vaultKeys
extension ShareEntity {
    @objc(addVaultKeysObject:)
    @NSManaged func addToVaultKeys(_ value: VaultKeyEntity)

    @objc(removeVaultKeysObject:)
    @NSManaged func removeFromVaultKeys(_ value: VaultKeyEntity)

    @objc(addVaultKeys:)
    @NSManaged func addToVaultKeys(_ values: NSSet)

    @objc(removeVaultKeys:)
    @NSManaged func removeFromVaultKeys(_ values: NSSet)
}

extension ShareEntity {
    // swiftlint:disable:next cyclomatic_complexity
    func toShare() throws -> Share {
        guard let shareID = shareID else {
            throw CoreDataError.corrupted(object: self, property: "shareID")
        }

        guard let vaultID = vaultID else {
            throw CoreDataError.corrupted(object: self, property: "vaultID")
        }

        guard let targetID = targetID else {
            throw CoreDataError.corrupted(object: self, property: "targetID")
        }

        guard let acceptanceSignature = acceptanceSignature else {
            throw CoreDataError.corrupted(object: self, property: "acceptanceSignature")
        }

        guard let inviterEmail = inviterEmail else {
            throw CoreDataError.corrupted(object: self, property: "inviterEmail")
        }

        guard let inviterAcceptanceSignature = inviterAcceptanceSignature else {
            throw CoreDataError.corrupted(object: self, property: "inviterAcceptanceSignature")
        }

        guard let signingKey = signingKey else {
            throw CoreDataError.corrupted(object: self, property: "signingKey")
        }

        guard let contentRotationID = contentRotationID else {
            throw CoreDataError.corrupted(object: self, property: "contentRotationID")
        }

        guard let contentEncryptedAddressSignature = contentEncryptedAddressSignature else {
            throw CoreDataError.corrupted(object: self, property: "contentEncryptedAddressSignature")
        }

        guard let contentEncryptedVaultSignature = contentEncryptedVaultSignature else {
            throw CoreDataError.corrupted(object: self, property: "contentEncryptedVaultSignature")
        }

        guard let contentSignatureEmail = contentSignatureEmail else {
            throw CoreDataError.corrupted(object: self, property: "contentSignatureEmail")
        }

        return .init(shareID: shareID,
                     vaultID: vaultID,
                     targetType: targetType,
                     targetID: targetID,
                     permission: permission,
                     acceptanceSignature: acceptanceSignature,
                     inviterEmail: inviterEmail,
                     inviterAcceptanceSignature: inviterAcceptanceSignature,
                     signingKey: signingKey,
                     signingKeyPassphrase: signingKeyPassphrase,
                     content: content,
                     contentRotationID: contentRotationID,
                     contentEncryptedAddressSignature: contentEncryptedAddressSignature,
                     contentEncryptedVaultSignature: contentEncryptedVaultSignature,
                     contentSignatureEmail: contentSignatureEmail,
                     contentFormatVersion: contentFormatVersion,
                     expireTime: expireTime,
                     createTime: createTime)
    }

    func hydrate(from share: Share, userId: String) {
        acceptanceSignature = share.acceptanceSignature
        content = share.content
        contentEncryptedAddressSignature = share.contentEncryptedAddressSignature
        contentEncryptedVaultSignature = share.contentEncryptedVaultSignature
        contentFormatVersion = share.contentFormatVersion
        contentRotationID = share.contentRotationID
        contentSignatureEmail = share.contentSignatureEmail
        createTime = share.createTime
        expireTime = share.expireTime ?? -1
        inviterAcceptanceSignature = share.inviterAcceptanceSignature
        inviterEmail = share.inviterEmail
        permission = share.permission
        shareID = share.shareID
        signingKey = share.signingKey
        signingKeyPassphrase = share.signingKeyPassphrase
        targetID = share.targetID
        targetType = share.targetType
        vaultID = share.vaultID
        userID = userId
    }
}
