//
// UserProfileEntity.swift
// Proton Pass - Created on 14/05/2024.
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

// Remove later
// periphery:ignore:all
import CoreData
import CryptoKit
import Entities
import Foundation
import ProtonCoreLogin

@objc(UserProfileEntity)
final class UserProfileEntity: NSManagedObject {}

extension UserProfileEntity: Identifiable {}

extension UserProfileEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }

    @NSManaged var userID: String
    @NSManaged var updateTime: Int64
    @NSManaged var isActive: Bool

    /// Symmetrically encrypted
    @NSManaged var encryptedData: Data
}

extension UserProfileEntity {
    func toUserProfile(_ key: SymmetricKey) throws -> UserProfile {
        let data = try key.decrypt(encryptedData)
        let userData = try JSONDecoder().decode(UserData.self, from: data)

        return UserProfile(userdata: userData, isActive: isActive, updateTime: Double(updateTime))
    }
}

extension UserProfileEntity {
    func hydrate(userData: UserData, key: SymmetricKey) throws {
        let data = try JSONEncoder().encode(userData)
        userID = userData.user.ID
        updateTime = Int64(Date.now.timeIntervalSince1970)
        encryptedData = try key.encrypt(data)
        isActive = false
    }
}
