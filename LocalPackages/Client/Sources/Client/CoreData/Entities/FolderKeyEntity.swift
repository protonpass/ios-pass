//
// FolderKeyEntity.swift
// Proton Pass - Created on 01/12/2025.
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

@objc(FolderKeyEntity)
final class FolderKeyEntity: NSManagedObject {}

extension FolderKeyEntity: Identifiable {}

extension FolderKeyEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<FolderKeyEntity> {
        NSFetchRequest<FolderKeyEntity>(entityName: "FolderKeyEntity")
    }

    @NSManaged var createTime: Int64
    @NSManaged var folderKeyID: String
    @NSManaged var folderID: String
    @NSManaged var keyRotation: Int64
    @NSManaged var encryptedKey: String
    @NSManaged var vaultID: String
    @NSManaged var userID: String
//    @NSManaged var key: String
//    @NSManaged var keyRotation: Int64
//    @NSManaged var invite: UserInviteEntity
}

// extension InviteKeyEntity {
//    var toInviteKey: InviteKey {
//        .init(key: key, keyRotation: keyRotation)
//    }
//
//    func hydrate(with key: InviteKey) {
//        self.key = key.key
//        keyRotation = key.keyRotation
//    }
// }

// CREATE TABLE `FolderKey` (
//  `FolderKeyID` integer unsigned NOT NULL AUTO_INCREMENT,
//  `VaultID` bigint unsigned NOT NULL,
////  `FolderID` integer unsigned NOT NULL,
////  `KeyRotation` smallint unsigned NOT NULL,
////  `EncryptedFolderKey` blob NOT NULL,
////  `CreateTime` integer unsigned NOT NULL,
//  PRIMARY KEY (`FolderKeyID`),
//  UNIQUE KEY `VaultIDFolderIDKeyRotation` (`VaultID`,`FolderID`,`KeyRotation`)
// ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
//
//
// @objc(ShareKeyEntity)
// final class ShareKeyEntity: NSManagedObject {}
//
// extension ShareKeyEntity: Identifiable {}
//
// extension ShareKeyEntity {
//    @nonobjc
//    class func fetchRequest() -> NSFetchRequest<ShareKeyEntity> {
//        NSFetchRequest<ShareKeyEntity>(entityName: "ShareKeyEntity")
//    }
//
//    @NSManaged var key: String
//    @NSManaged var keyRotation: Int64
//    @NSManaged var shareID: String
//    @NSManaged var symmetricallyEncryptedKey: String
//    @NSManaged var userID: String
//    @NSManaged var userKeyID: String
// }
//
// extension ShareKeyEntity {
//    func toSymmetricallyEncryptedShareKey() -> SymmetricallyEncryptedShareKey {
//        .init(encryptedKey: symmetricallyEncryptedKey,
//              shareId: shareID,
//              userId: userID,
//              shareKey: .init(createTime: createTime,
//                              key: key,
//                              keyRotation: keyRotation,
//                              userKeyID: userKeyID))
//    }
//
//    func hydrate(from symmetricallyEncryptedShareKey: SymmetricallyEncryptedShareKey) {
//        createTime = symmetricallyEncryptedShareKey.shareKey.createTime
//        key = symmetricallyEncryptedShareKey.shareKey.key
//        keyRotation = symmetricallyEncryptedShareKey.shareKey.keyRotation
//        shareID = symmetricallyEncryptedShareKey.shareId
//        symmetricallyEncryptedKey = symmetricallyEncryptedShareKey.encryptedKey
//        userID = symmetricallyEncryptedShareKey.userId
//        userKeyID = symmetricallyEncryptedShareKey.shareKey.userKeyID
//    }
// }
