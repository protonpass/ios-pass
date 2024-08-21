//
// LocalSearchEntryDatasource.swift
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

public protocol LocalSearchEntryDatasourceProtocol: Sendable {
    /// Get all entries related to a share
    func getAllEntries(shareId: String) async throws -> [SearchEntry]

    /// Get all entries related to a user
    func getAllEntries(userId: String) async throws -> [SearchEntry]

    func upsert(item: any ItemIdentifiable, userId: String, date: Date) async throws

    /// Remove all entries related to a share
    func removeAllEntries(shareId: String) async throws

    /// Remove all entries related to a user
    func removeAllEntries(userId: String) async throws

    /// Remove a single entry
    func remove(item: any ItemIdentifiable) async throws
}

public final class LocalSearchEntryDatasource: LocalDatasource, LocalSearchEntryDatasourceProtocol {}

public extension LocalSearchEntryDatasource {
    func getAllEntries(shareId: String) async throws -> [SearchEntry] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = SearchEntryEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        fetchRequest.sortDescriptors = [.init(key: "time", ascending: false)]
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.map { $0.toSearchEntry() }
    }

    func getAllEntries(userId: String) async throws -> [SearchEntry] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = SearchEntryEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        fetchRequest.sortDescriptors = [.init(key: "time", ascending: false)]
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.map { $0.toSearchEntry() }
    }

    func upsert(item: any ItemIdentifiable, userId: String, date: Date) async throws {
        try await upsert(items: [item],
                         fetchPredicate: NSPredicate(format: "itemID == %@ AND shareID == %@",
                                                     item.itemId,
                                                     item.shareId),
                         itemComparisonKey: { item in
                             SearchEntryKeyComparison(itemId: item.itemId, shareId: item.shareId)
                         },
                         entityComparisonKey: { entity in
                             SearchEntryKeyComparison(itemId: entity.itemID, shareId: entity.shareID)
                         },
                         updateEntity: { (entity: SearchEntryEntity, item: ItemIdentifiable) in
                             entity.hydrate(from: item, userId: userId, date: date)
                         },
                         insertItems: { [weak self] item, context in
                             guard let self else { return }
                             try await insert(items: item, userId: userId, date: date, context: context)
                         })
    }

    func removeAllEntries(shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "SearchEntryEntity")
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func removeAllEntries(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "SearchEntryEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func remove(item: any ItemIdentifiable) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "SearchEntryEntity")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "itemID = %@", item.itemId),
            .init(format: "shareID = %@", item.shareId)
        ])
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    /// Temporary migration, can be removed after july 2025
    func updateSearchEntries(with userId: String) async throws {
        let entries = try await getAllEntries(userId: "")
        try await removeAllEntries(userId: userId)
        for entry in entries {
            try await upsert(item: entry,
                             userId: userId,
                             date: Date(timeIntervalSince1970: TimeInterval(entry.time)))
        }
    }
}

private extension LocalSearchEntryDatasource {
    struct SearchEntryKeyComparison: Hashable {
        let itemId: String
        let shareId: String
    }

    func insert(items: [any ItemIdentifiable],
                userId: String,
                date: Date,
                context: NSManagedObjectContext) async throws {
        let batchInsertRequest =
            newBatchInsertRequest(entity: SearchEntryEntity.entity(context: context),
                                  sourceItems: items) { managedObject, item in
                (managedObject as? SearchEntryEntity)?.hydrate(from: item,
                                                               userId: userId,
                                                               date: date)
            }
        try await execute(batchInsertRequest: batchInsertRequest, context: context)
    }
}
