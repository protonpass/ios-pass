//
// LastUsedTimeEntity.swift
// Proton Pass - Created on 26/10/2023.
// Copyright (c) 2023 Proton Technologies AG
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

@objc(LastUsedTimeEntity)
public class LastUsedTimeEntity: NSManagedObject {}

extension LastUsedTimeEntity: Identifiable {}

extension LastUsedTimeEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<LastUsedTimeEntity> {
        NSFetchRequest<LastUsedTimeEntity>(entityName: "LastUsedTimeEntity")
    }

    @NSManaged var itemId: String
    @NSManaged var shareId: String
    @NSManaged var lastUseTime: Double
}

extension LastUsedTimeEntity {
    var toLastUsedTimeItem: LastUsedTimeItem {
        LastUsedTimeItem(shareId: shareId, itemId: itemId, lastUsedTime: lastUseTime)
    }

    func hydrate(from lastUsedTimeItem: LastUsedTimeItem) {
        itemId = lastUsedTimeItem.itemId
        shareId = lastUsedTimeItem.shareId
        lastUseTime = lastUsedTimeItem.lastUsedTime
    }
}
