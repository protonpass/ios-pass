//
// PasswordEntity.swift
// Proton Pass - Created on 09/04/2025.
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

@objc(PasswordEntity)
final class PasswordEntity: NSManagedObject {}

extension PasswordEntity: Identifiable {}

extension PasswordEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<PasswordEntity> {
        NSFetchRequest<PasswordEntity>(entityName: "PasswordEntity")
    }

    @NSManaged var userID: String
    @NSManaged var id: String
    @NSManaged var creationTime: Int64
    @NSManaged var symmetricallyEncryptedValue: String
}

extension PasswordEntity {
    var toGeneratedPassword: GeneratedPassword {
        .init(id: id, creationTimestamp: Int(creationTime))
    }

    func hydrate(userID: String,
                 id: String,
                 creationTime: TimeInterval,
                 symmetricallyEncryptedValue: String) {
        self.userID = userID
        self.id = id
        self.creationTime = Int64(creationTime)
        self.symmetricallyEncryptedValue = symmetricallyEncryptedValue
    }
}
