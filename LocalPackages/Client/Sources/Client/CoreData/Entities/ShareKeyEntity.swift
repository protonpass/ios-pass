//
// ShareKeyEntity.swift
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

@objc(ShareKeyEntity)
public final class ShareKeyEntity: NSManagedObject {}

extension ShareKeyEntity: Identifiable {}

extension ShareKeyEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<ShareKeyEntity> {
        NSFetchRequest<ShareKeyEntity>(entityName: "ShareKeyEntity")
    }

    @NSManaged var createTime: Int64
    @NSManaged var key: String
    @NSManaged var keyRotation: Int64
    @NSManaged var shareID: String
    @NSManaged var symmetricallyEncryptedKey: String
    @NSManaged var userKeyID: String
}

extension ShareKeyEntity {
    func toSymmetricallyEncryptedShareKey() -> SymmetricallyEncryptedShareKey {
        .init(encryptedKey: symmetricallyEncryptedKey,
              shareId: shareID,
              shareKey: .init(createTime: createTime,
                              key: key,
                              keyRotation: keyRotation,
                              userKeyID: userKeyID))
    }

    func hydrate(from symmetricallyEncryptedShareKey: SymmetricallyEncryptedShareKey) {
        createTime = symmetricallyEncryptedShareKey.shareKey.createTime
        key = symmetricallyEncryptedShareKey.shareKey.key
        keyRotation = symmetricallyEncryptedShareKey.shareKey.keyRotation
        shareID = symmetricallyEncryptedShareKey.shareId
        symmetricallyEncryptedKey = symmetricallyEncryptedShareKey.encryptedKey
        userKeyID = symmetricallyEncryptedShareKey.shareKey.userKeyID
    }
}
