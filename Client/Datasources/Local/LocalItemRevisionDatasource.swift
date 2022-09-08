//
// LocalItemRevisionDatasource.swift
// Proton Pass - Created on 14/08/2022.
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

public protocol LocalItemRevisionDatasourceProtocol {
    func getItemRevision(shareId: String, itemId: String) async throws -> ItemRevision?
    func getItemRevisions(shareId: String) async throws -> [ItemRevision]
    func upsertItemRevisions(_ itemRevisions: [ItemRevision], shareId: String) async throws
    func removeAllItemRevisions(shareId: String) async throws
}

public final class LocalItemRevisionDatasource: BaseLocalDatasource {}

extension LocalItemRevisionDatasource: LocalItemRevisionDatasourceProtocol {
    public func getItemRevision(shareId: String,
                                itemId: String) async throws -> ItemRevision? {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = ItemRevisionEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                .init(format: "shareID = %@", shareId),
                .init(format: "itemID = %@", itemId)
            ])
        let itemRevisionEntities = try await execute(fetchRequest: fetchRequest,
                                                     context: taskContext)
        return try itemRevisionEntities.map { try $0.toItemRevision() }.first
    }

    public func getItemRevisions(shareId: String) async throws -> [ItemRevision] {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = ItemRevisionEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        fetchRequest.sortDescriptors = [.init(key: "modifyTime", ascending: false)]
        let itemRevisionEntities = try await execute(fetchRequest: fetchRequest,
                                                     context: taskContext)
        return try itemRevisionEntities.map { try $0.toItemRevision() }
    }

    public func upsertItemRevisions(_ itemRevisions: [ItemRevision],
                                    shareId: String) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
        newBatchInsertRequest(entity: ItemRevisionEntity.entity(context: taskContext),
                              sourceItems: itemRevisions) { managedObject, itemRevision in
            (managedObject as? ItemRevisionEntity)?.hydrate(from: itemRevision,
                                                            shareId: shareId)
        }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    public func removeAllItemRevisions(shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ItemRevisionEntity")
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
