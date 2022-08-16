//
// LocalItemKeyDatasource.swift
// Proton Pass - Created on 16/08/2022.
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

public protocol LocalItemKeyDatasourceProtocol {
    func getItemKey(shareId: String, rotationId: String) async throws -> ItemKey?
    func getItemKeys(shareId: String, page: Int, pageSize: Int) async throws -> [ItemKey]
    func getItemKeyCount(shareId: String) async throws -> Int
    func upsertItemKeys(_ itemKeys: [ItemKey], shareId: String) async throws
    func removeAllItemKeys(shareId: String) async throws
}

public final class LocalItemKeyDatasource: BaseLocalDatasource {}

extension LocalItemKeyDatasource: LocalItemKeyDatasourceProtocol {
    public func getItemKey(shareId: String, rotationId: String) async throws -> ItemKey? {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = ItemKeyEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                .init(format: "shareID = %@", shareId),
                .init(format: "rotationID = %@", rotationId)
            ])
        let itemKeyEntities = try await execute(fetchRequest: fetchRequest,
                                                context: taskContext)
        return try itemKeyEntities.map { try $0.toItemKey() }.first
    }

    public func getItemKeys(shareId: String,
                            page: Int,
                            pageSize: Int) async throws -> [ItemKey] {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = itemKeyEntityFetchRequest(shareId: shareId)
        fetchRequest.fetchLimit = pageSize
        fetchRequest.fetchOffset = page * pageSize
        let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try itemEntities.map { try $0.toItemKey() }
    }

    public func getItemKeyCount(shareId: String) async throws -> Int {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = itemKeyEntityFetchRequest(shareId: shareId)
        return try await count(fetchRequest: fetchRequest, context: taskContext)
    }

    public func upsertItemKeys(_ itemKeys: [ItemKey], shareId: String) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
        newBatchInsertRequest(entity: ItemKeyEntity.entity(),
                              sourceItems: itemKeys) { managedObject, itemKey in
            (managedObject as? ItemKeyEntity)?.hydrate(from: itemKey, shareId: shareId)
        }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    public func removeAllItemKeys(shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ItemKeyEntity")
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    private func itemKeyEntityFetchRequest(shareId: String) -> NSFetchRequest<ItemKeyEntity> {
        let fetchRequest = ItemKeyEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        return fetchRequest
    }
}
