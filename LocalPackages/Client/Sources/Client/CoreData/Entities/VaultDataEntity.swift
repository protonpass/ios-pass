//
// VaultDataEntity.swift
// Proton Pass - Created on 17/09/2025.
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

@objc(VaultDataEntity)
final class VaultDataEntity: NSManagedObject {}

extension VaultDataEntity: Identifiable {}

extension VaultDataEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<VaultDataEntity> {
        NSFetchRequest<VaultDataEntity>(entityName: "VaultDataEntity")
    }

    @NSManaged var content: String
    @NSManaged var contentKeyRotation: Int64
    @NSManaged var contentFormatVersion: Int64
    @NSManaged var memberCount: Int64
    @NSManaged var itemCount: Int64
    @NSManaged var invite: UserInviteEntity
}

extension VaultDataEntity {
    var toVaultData: VaultData {
        .init(content: content,
              contentKeyRotation: Int(contentKeyRotation),
              contentFormatVersion: Int(contentFormatVersion),
              memberCount: Int(memberCount),
              itemCount: Int(itemCount))
    }

    func hydrate(with data: VaultData) {
        content = data.content
        contentKeyRotation = Int64(data.contentKeyRotation)
        contentFormatVersion = Int64(data.contentFormatVersion)
        memberCount = Int64(data.memberCount)
        itemCount = Int64(data.itemCount)
    }
}
