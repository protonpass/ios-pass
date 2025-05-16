//
// UserEventIDEntity.swift
// Proton Pass - Created on 16/05/2025.
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
import Foundation

@objc(UserEventIDEntity)
final class UserEventIDEntity: NSManagedObject {}

extension UserEventIDEntity: Identifiable {}

extension UserEventIDEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<UserEventIDEntity> {
        NSFetchRequest<UserEventIDEntity>(entityName: "UserEventIDEntity")
    }

    @NSManaged var userID: String
    @NSManaged var lastEventID: String?
}

extension UserEventIDEntity {
    func hydrate(userId: String, lastEventId: String) {
        userID = userId
        lastEventID = lastEventId
    }
}
