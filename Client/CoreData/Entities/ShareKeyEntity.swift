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
    @NSManaged var key: String?
    @NSManaged var keyRotation: Int64
    @NSManaged var shareID: String?
}

extension ShareKeyEntity {
    func toShareKey() throws -> ShareKey {
        guard let key else {
            throw PPClientError.coreData(.corrupted(object: self, property: "key"))
        }

        return .init(key: key, keyRotation: keyRotation, createTime: createTime)
    }

    func hydrate(from shareKey: ShareKey, shareId: String) {
        createTime = shareKey.createTime
        key = shareKey.key
        keyRotation = shareKey.keyRotation
        shareID = shareId
    }
}

extension ShareKeyEntity {
    class func allVaultKeysFetchRequest(shareId: String) -> NSFetchRequest<ShareKeyEntity> {
        let fetchRequest = fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %s", shareId)
        return fetchRequest
    }
}
