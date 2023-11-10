//
// PublicKeyEntity.swift
// Proton Pass - Created on 17/08/2022.
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
import Entities
import Foundation

@objc(PublicKeyEntity)
public class PublicKeyEntity: NSManagedObject {}

extension PublicKeyEntity: Identifiable {}

extension PublicKeyEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<PublicKeyEntity> {
        NSFetchRequest<PublicKeyEntity>(entityName: "PublicKeyEntity")
    }

    @NSManaged var value: String?
    @NSManaged var email: String?
}

extension PublicKeyEntity {
    func toPublicKey() throws -> PublicKey {
        guard let value else {
            throw PassError.coreData(.corrupted(object: self, property: "value"))
        }
        return .init(value: value)
    }

    func hydrate(from publicKey: PublicKey, email: String) {
        value = publicKey.value
        self.email = email
    }
}
