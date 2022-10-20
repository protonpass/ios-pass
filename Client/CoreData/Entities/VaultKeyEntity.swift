//
// VaultKeyEntity.swift
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

@objc(VaultKeyEntity)
public final class VaultKeyEntity: NSManagedObject {}

extension VaultKeyEntity: Identifiable {}

extension VaultKeyEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<VaultKeyEntity> {
        NSFetchRequest<VaultKeyEntity>(entityName: "VaultKeyEntity")
    }

    @NSManaged var createTime: Int64
    @NSManaged var key: String?
    @NSManaged var keyPassphrase: String?
    @NSManaged var keySignature: String?
    @NSManaged var rotation: Int64
    @NSManaged var rotationID: String?
    @NSManaged var shareID: String?
    @NSManaged var share: ShareEntity?
}

extension VaultKeyEntity {
    func toVaultKey() throws -> VaultKey {
        guard let rotationID else {
            throw CoreDataError.corrupted(object: self, property: "rotationID")
        }

        guard let key else {
            throw CoreDataError.corrupted(object: self, property: "key")
        }

        guard let keyPassphrase else {
            throw CoreDataError.corrupted(object: self, property: "keyPassphrase")
        }

        guard let keySignature else {
            throw CoreDataError.corrupted(object: self, property: "keySignature")
        }

        return .init(rotationID: rotationID,
                     rotation: rotation,
                     key: key,
                     keyPassphrase: keyPassphrase,
                     keySignature: keySignature,
                     createTime: createTime)
    }

    func hydrate(from vaultKey: VaultKey, shareId: String) {
        createTime = vaultKey.createTime
        key = vaultKey.key
        keyPassphrase = vaultKey.keyPassphrase
        keySignature = vaultKey.keySignature
        rotation = vaultKey.rotation
        rotationID = vaultKey.rotationID
        shareID = shareId
    }
}

extension VaultKeyEntity {
    class func allVaultKeysFetchRequest(shareId: String) -> NSFetchRequest<VaultKeyEntity> {
        let fetchRequest = fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %s", shareId)
        return fetchRequest
    }
}
