//
// LocalItemDatasource.swift
// Proton Pass - Created on 20/09/2022.
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

public protocol LocalItemDatasourceProtocol {
    /// Get a specific item
    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem?

    /// Get items by state
    func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem]

    /// Get total items of a share (both active and trashed ones)
    func getItemCount(shareId: String) async throws -> Int

    /// Insert or update a list of items
    func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws

    /// Trash or untrash items
    func upsertItems(_ items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem]) async throws

    /// Permanently delete items
    func deleteItems(_ items: [ItemToBeModified], shareId: String) async throws

    /// Nuke items of a share
    func removeAllItems(shareId: String) async throws
}

public final class LocalItemDatasource: BaseLocalDatasource {}

extension LocalItemDatasource: LocalItemDatasourceProtocol {
    public func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem? {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                .init(format: "shareID = %@", shareId),
                .init(format: "itemID = %@", itemId)
            ])
        let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try itemEntities.map { try $0.toEncryptedItem(shareId: shareId) }.first
    }

    public func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "shareID = %@", shareId),
            .init(format: "state = %d", state.rawValue)
        ])
        fetchRequest.sortDescriptors = [.init(key: "modifyTime", ascending: false)]
        let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try itemEntities.map { try $0.toEncryptedItem(shareId: shareId) }
    }

    public func getItemCount(shareId: String) async throws -> Int {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        return try await count(fetchRequest: fetchRequest, context: taskContext)
    }

    public func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let taskContext = newTaskContext(type: .insert)
        let entity = ItemEntity.entity(context: taskContext)
        let batchInsertRequest = newBatchInsertRequest(entity: entity,
                                                       sourceItems: items) { managedObject, item in
            (managedObject as? ItemEntity)?.hydrate(from: item)
        }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    public func upsertItems(_ items: [SymmetricallyEncryptedItem],
                            modifiedItems: [ModifiedItem]) async throws {
        let taskContext = newTaskContext(type: .insert)
        let entity = ItemEntity.entity(context: taskContext)
        let batchInsertRequest = newBatchInsertRequest(entity: entity,
                                                       sourceItems: items) { managedObject, item in
            (managedObject as? ItemEntity)?.hydrate(from: item)
        }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    public func deleteItems(_ items: [ItemToBeModified], shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        for item in items {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ItemEntity")
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                .init(format: "shareID = %@", shareId),
                .init(format: "itemID = %@", item.itemID)
            ])
            try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                              context: taskContext)
        }
    }

    public func removeAllItems(shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ItemEntity")
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
