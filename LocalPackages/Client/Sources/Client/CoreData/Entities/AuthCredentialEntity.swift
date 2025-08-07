//
// AuthCredentialEntity.swift
// Proton Pass - Created on 16/05/2024.
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
import ProtonCoreNetworking

@objc(AuthCredentialEntity)
final class AuthCredentialEntity: NSManagedObject {}

extension AuthCredentialEntity: Identifiable {}

extension AuthCredentialEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<AuthCredentialEntity> {
        NSFetchRequest<AuthCredentialEntity>(entityName: "AuthCredentialEntity")
    }

    @NSManaged var userID: String
    @NSManaged var module: String
    /// Symmetrically encrypted
    @NSManaged var encryptedData: Data
}

extension AuthCredentialEntity {
    func toAuthCredential(_ key: SymmetricKey) throws -> AuthCredential {
        let data = try key.decrypt(encryptedData)
        return try JSONDecoder().decode(AuthCredential.self, from: data)
    }
}

extension AuthCredentialEntity {
    func hydrate(userId: String,
                 authCredential: AuthCredential,
                 module: PassModule,
                 key: SymmetricKey) throws {
        let data = try JSONEncoder().encode(authCredential)
        userID = userId
        self.module = module.rawValue
        encryptedData = try key.encrypt(data)
    }
}
