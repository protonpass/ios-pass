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

public protocol LocalSearchEntryDatasourceProtocol: LocalDatasourceProtocol {
    func getAllEntries() async throws -> [SearchEntry]
    func upsert(entry: SearchEntry) async throws
    func remove(entry: SearchEntry) async throws
}

public extension LocalSearchEntryDatasourceProtocol {
    func getAllEntries() async throws -> [SearchEntry] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = SearchEntryEntity.fetchRequest()
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.map { $0.toSearchEntry() }
    }

    func upsert(entry: SearchEntry) async throws {
        let taskContext = newTaskContext(type: .insert)
        let batchInsertRequest =
        newBatchInsertRequest(entity: SearchEntryEntity.entity(context: taskContext),
                              sourceItems: [entry]) { managedObject, entry in
            (managedObject as? SearchEntryEntity)?.hydrate(from: entry)
        }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    func remove(entry: SearchEntry) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "SearchEntryEntity")
        fetchRequest.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                .init(format: "itemID = %@", entry.itemID),
                .init(format: "shareID = %@", entry.shareID)
            ])
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
