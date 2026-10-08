//
// CompromisedPasswordCheckEntity.swift
// Proton Pass - Created on 18/06/2026.
// Copyright (c) 2026 Proton Technologies AG
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
//

import CoreData
import Entities

@objc(CompromisedPasswordCheckEntity)
final class CompromisedPasswordCheckEntity: NSManagedObject {}

extension CompromisedPasswordCheckEntity: Identifiable {}

extension CompromisedPasswordCheckEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<CompromisedPasswordCheckEntity> {
        NSFetchRequest<CompromisedPasswordCheckEntity>(entityName: "CompromisedPasswordCheckEntity")
    }

    @NSManaged var userID: String
    @NSManaged var shareID: String
    @NSManaged var itemID: String
    @NSManaged var passwordHash: String
    @NSManaged var prefix: String
    @NSManaged var etag: String
    @NSManaged var breachCount: Int64
    @NSManaged var checkedAt: Int64
}

extension CompromisedPasswordCheckEntity {
    func toCompromisedPasswordCheck() -> CompromisedPasswordCheck {
        .init(shareId: shareID,
              itemId: itemID,
              passwordHash: passwordHash,
              prefix: prefix,
              etag: etag,
              breachCount: Int(breachCount),
              checkedAt: Int(checkedAt))
    }
}

extension CompromisedPasswordCheckEntity {
    static func batchInsertValues(from check: CompromisedPasswordCheck, userId: String) -> [String: Any] {
        [
            #keyPath(userID): userId,
            #keyPath(shareID): check.shareId,
            #keyPath(itemID): check.itemId,
            #keyPath(passwordHash): check.passwordHash,
            #keyPath(prefix): check.prefix,
            #keyPath(etag): check.etag,
            #keyPath(breachCount): Int64(check.breachCount),
            #keyPath(checkedAt): Int64(check.checkedAt)
        ]
    }
}
