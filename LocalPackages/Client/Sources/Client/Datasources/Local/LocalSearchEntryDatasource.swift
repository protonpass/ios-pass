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

public final class LocalSearchEntryDatasource: LocalDatasource, LocalSearchEntryDatasourceProtocol,
    @unchecked Sendable {}

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
        try await upsert([item],
                         entityType: SearchEntryEntity.self,
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
}
