//
// ItemTextAutoFillEntity.swift
// Proton Pass - Created on 10/10/2024.
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
import Entities

@objc(ItemTextAutoFillEntity)
final class ItemTextAutoFillEntity: NSManagedObject {}

extension ItemTextAutoFillEntity: Identifiable {}

extension ItemTextAutoFillEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<ItemTextAutoFillEntity> {
        NSFetchRequest<ItemTextAutoFillEntity>(entityName: "ItemTextAutoFillEntity")
    }

    @NSManaged var itemID: String
    @NSManaged var shareID: String
    @NSManaged var time: Int64
    @NSManaged var userID: String
}

extension ItemTextAutoFillEntity {
    func toItemTextAutoFill() -> ItemTextAutoFill {
        .init(shareId: shareID,
              itemId: itemID,
              timestamp: TimeInterval(time),
              userId: userID)
    }

    func hydrate(from item: any ItemIdentifiable, userId: String, date: Date) {
        itemID = item.itemId
        shareID = item.shareId
        time = Int64(date.timeIntervalSince1970)
        userID = userId
    }
}
