//
// LocalTextAutoFillHistoryEntryEntityDatasource.swift
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

// swiftlint:disable:next type_name
public protocol LocalTextAutoFillHistoryEntryDatasourceProtocol: Sendable {
    func getMostRecentEntries(userId: String, count: Int) async throws -> [TextAutoFillHistoryEntry]
    func upsert(item: any ItemIdentifiable, userId: String, date: Date) async throws
    func removeAll() async throws
}

public final class LocalTextAutoFillHistoryEntryDatasource:
    LocalDatasource, LocalTextAutoFillHistoryEntryDatasourceProtocol, @unchecked Sendable {}

public extension LocalTextAutoFillHistoryEntryDatasource {
    func getMostRecentEntries(userId: String, count: Int) async throws -> [TextAutoFillHistoryEntry] {
        let context = newTaskContext(type: .fetch)
        let request = TextAutoFillHistoryEntryEntity.fetchRequest()
        request.predicate = .init(format: "userID = %@", userId)
        request.sortDescriptors = [.init(key: "time", ascending: false)]
        request.fetchLimit = count
        let entities = try await execute(fetchRequest: request, context: context)
        return entities.map(\.toTextAutoFillHistoryEntry)
    }

    func upsert(item: any ItemIdentifiable, userId: String, date: Date) async throws {
        try await upsert([item],
                         entityType: TextAutoFillHistoryEntryEntity.self,
                         fetchPredicate: NSPredicate(format: "itemID == %@ AND shareID == %@",
                                                     item.itemId,
                                                     item.shareId),
                         isEqual: { item, entity in
                             item.itemId == entity.itemID && item.shareId == entity.shareID
                         },
                         hydrate: { item, entity in
                             entity.hydrate(from: item, userId: userId, date: date)
                         })
    }

    func removeAll() async throws {
        let context = newTaskContext(type: .delete)
        let request = NSFetchRequest<any NSFetchRequestResult>(entityName: "TextAutoFillHistoryEntryEntity")
        try await execute(batchDeleteRequest: .init(fetchRequest: request),
                          context: context)
    }
}
