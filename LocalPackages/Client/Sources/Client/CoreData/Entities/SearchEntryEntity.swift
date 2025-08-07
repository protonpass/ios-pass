//
// SearchEntryEntity.swift
// Proton Pass - Created on 16/03/2023.
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

@objc(SearchEntryEntity)
final class SearchEntryEntity: NSManagedObject {}

extension SearchEntryEntity: Identifiable {}

extension SearchEntryEntity {
    @nonobjc
    class func fetchRequest() -> NSFetchRequest<SearchEntryEntity> {
        NSFetchRequest<SearchEntryEntity>(entityName: "SearchEntryEntity")
    }

    @NSManaged var itemID: String
    @NSManaged var shareID: String
    @NSManaged var time: Int64
    @NSManaged var userID: String
}

extension SearchEntryEntity {
    func toSearchEntry() -> SearchEntry {
        .init(itemID: itemID, shareID: shareID, time: time)
    }

    func hydrate(from item: any ItemIdentifiable, userId: String, date: Date) {
        itemID = item.itemId
        shareID = item.shareId
        time = Int64(date.timeIntervalSince1970)
        userID = userId
    }
}
