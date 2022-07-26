//
// CDShare+CDShare+CoreDataProperties.swift
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

extension CDShare {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<CDShare> {
        NSFetchRequest<CDShare>(entityName: "CDShare")
    }

    @NSManaged var acceptanceSignature: String?
    @NSManaged var content: String?
    @NSManaged var contentEncryptedAddressSignature: String?
    @NSManaged var contentEncryptedVaultSignature: String?
    @NSManaged var contentFormatVersion: Int64
    @NSManaged var contentRotationID: String?
    @NSManaged var contentSignatureEmail: String?
    @NSManaged var createTime: Double
    @NSManaged var expireTime: Double
    @NSManaged var inviterAcceptanceSignature: String?
    @NSManaged var inviterEmail: String?
    @NSManaged var permission: Int64
    @NSManaged var shareID: String?
    @NSManaged var signingKey: String?
    @NSManaged var signingKeyPassphrase: String?
    @NSManaged var targetID: String?
    @NSManaged var targetType: Int64
    @NSManaged var userID: String?
    @NSManaged var vaultID: String?
    @NSManaged var itemKeys: NSSet?
    @NSManaged var vaultKeys: NSSet?
}

// MARK: Generated accessors for itemKeys
extension CDShare {
    @objc(addItemKeysObject:)
    @NSManaged func addToItemKeys(_ value: CDItemKey)

    @objc(removeItemKeysObject:)
    @NSManaged func removeFromItemKeys(_ value: CDItemKey)

    @objc(addItemKeys:)
    @NSManaged func addToItemKeys(_ values: NSSet)

    @objc(removeItemKeys:)
    @NSManaged func removeFromItemKeys(_ values: NSSet)
}

// MARK: Generated accessors for vaultKeys
extension CDShare {
    @objc(addVaultKeysObject:)
    @NSManaged func addToVaultKeys(_ value: CDVaultKey)

    @objc(removeVaultKeysObject:)
    @NSManaged func removeFromVaultKeys(_ value: CDVaultKey)

    @objc(addVaultKeys:)
    @NSManaged func addToVaultKeys(_ values: NSSet)

    @objc(removeVaultKeys:)
    @NSManaged func removeFromVaultKeys(_ values: NSSet)
}

extension CDShare: Identifiable {}
