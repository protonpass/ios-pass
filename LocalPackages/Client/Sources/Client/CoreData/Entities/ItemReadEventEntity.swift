//
// ItemReadEventEntity.swift
// Proton Pass - Created on 10/06/2024.
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

@objc(ItemReadEventEntity)
final class ItemReadEventEntity: NSManagedObject {}

extension ItemReadEventEntity: Identifiable {}

extension ItemReadEventEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<ItemReadEventEntity> {
        NSFetchRequest<ItemReadEventEntity>(entityName: "ItemReadEventEntity")
    }

    @NSManaged var shareID: String
    @NSManaged var itemID: String
    @NSManaged var time: Double
    @NSManaged var userID: String
    @NSManaged var uuid: String
}

extension ItemReadEventEntity {
    func toItemReadEvent() -> ItemReadEvent {
        .init(uuid: uuid,
              shareId: shareID,
              itemId: itemID,
              timestamp: time)
    }
}

extension ItemReadEventEntity {
    func hydrate(from event: ItemReadEvent, userId: String) {
        shareID = event.shareId
        itemID = event.itemId
        time = event.timestamp
        userID = userId
        uuid = event.uuid
    }
}
