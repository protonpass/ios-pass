//
// UserPreferencesEntity.swift
// Proton Pass - Created on 29/03/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import CryptoKit
import Entities
import Foundation

@objc(UserPreferencesEntity)
final class UserPreferencesEntity: NSManagedObject {}

extension UserPreferencesEntity: Identifiable {}

extension UserPreferencesEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<UserPreferencesEntity> {
        NSFetchRequest<UserPreferencesEntity>(entityName: "UserPreferencesEntity")
    }

    @NSManaged var userID: String

    /// Symmetrically encrypted
    @NSManaged var encryptedContent: Data
}

extension UserPreferencesEntity {
    func toUserPreferences(_ key: SymmetricKey) throws -> UserPreferences {
        try JSONDecoder().decode(UserPreferences.self, from: key.decrypt(encryptedContent))
    }
}

extension UserPreferencesEntity {
    func hydrate(preferences: UserPreferences,
                 userId: String,
                 key: SymmetricKey) throws {
        userID = userId
        let data = try JSONEncoder().encode(preferences)
        encryptedContent = try key.encrypt(data)
    }
}
