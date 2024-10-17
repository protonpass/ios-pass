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
import Entities

// sourcery: AutoMockable
public protocol LocalItemDatasourceProtocol: Sendable {
    // Get all items (both active & trashed)
    func getAllItems(userId: String) async throws -> [SymmetricallyEncryptedItem]

    func getAllPinnedItems(userId: String) async throws -> [SymmetricallyEncryptedItem]

    // Get all items by state
    func getItems(userId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem]

    /// Get items by state
    func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem]

    /// Get a specific item
    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem?

    /// Get alias item by alias email
    func getAliasItem(email: String) async throws -> SymmetricallyEncryptedItem?

    // periphery:ignore
    /// Get total items of a share (both active and trashed ones)
    func getItemCount(shareId: String) async throws -> Int

    /// Insert or update a list of items
    func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws

    /// Trash or untrash items
    func upsertItems(_ items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem]) async throws

    /// Bulk update `LastUseItem`
    func update(lastUseItems: [LastUseItem], shareId: String) async throws

    /// Permanently delete items
    func deleteItems(_ items: [SymmetricallyEncryptedItem]) async throws

    /// Permanently delete items with given ids
    func deleteItems(itemIds: [String], shareId: String) async throws

    /// Nuke items of all shares
    func removeAllItems() async throws

    /// Nuke items of a share
    func removeAllItems(shareId: String) async throws

    /// Nuke items of a specific user
    func removeAllItems(userId: String) async throws

    // MARK: - AutoFill related operations

    /// Get all active log in items
    func getActiveLogInItems(userId: String) async throws -> [SymmetricallyEncryptedItem]

    func getItems(for items: [any ItemIdentifiable]) async throws -> [SymmetricallyEncryptedItem]
}

public final class LocalItemDatasource: LocalDatasource, LocalItemDatasourceProtocol, @unchecked Sendable {}

public extension LocalItemDatasource {
    func getAllItems(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try itemEntities.map { try $0.toEncryptedItem() }
    }

    func getAllPinnedItems(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "pinned = %d", true)
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "pinned = %d", true),
            .init(format: "userID = %@", userId)
        ])
        let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try itemEntities.map { try $0.toEncryptedItem() }
    }

    func getItems(userId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "state = %d", state.rawValue),
            .init(format: "userID = %@", userId)
        ])
        let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try itemEntities.map { try $0.toEncryptedItem() }
    }

    func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "shareID = %@", shareId),
            .init(format: "state = %d", state.rawValue)
        ])
        fetchRequest.sortDescriptors = [.init(key: "modifyTime", ascending: false)]
        let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try itemEntities.map { try $0.toEncryptedItem() }
    }

    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem? {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "shareID = %@", shareId),
            .init(format: "itemID = %@", itemId)
        ])
        let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try itemEntities.map { try $0.toEncryptedItem() }.first
    }

    func getAliasItem(email: String) async throws -> SymmetricallyEncryptedItem? {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "aliasEmail = %@", email)
        let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        assert(itemEntities.count <= 1, "Could not have more than 1 matched alias item")
        return try itemEntities.map { try $0.toEncryptedItem() }.first
    }

    // periphery:ignore
    func getItemCount(shareId: String) async throws -> Int {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        return try await count(fetchRequest: fetchRequest, context: taskContext)
    }

    func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        try await upsert(items,
                         entityType: ItemEntity.self,
                         fetchPredicate: NSPredicate(format: "itemID IN %@ AND shareID IN %@",
                                                     items.map(\.item.itemID),
                                                     items.map(\.shareId)),
                         isEqual: { item, entity in
                             item.shareId == entity.shareID && item.itemId == entity.itemID
                         },
                         hydrate: { item, entity in
                             entity.hydrate(from: item)
                         })
    }

    func upsertItems(_ items: [SymmetricallyEncryptedItem],
                     modifiedItems: [ModifiedItem]) async throws {
        for item in items {
            if let modifiedItem = modifiedItems.first(where: { $0.itemID == item.item.itemID }) {
                let modifiedItem = Item(itemID: item.item.itemID,
                                        revision: modifiedItem.revision,
                                        contentFormatVersion: item.item.contentFormatVersion,
                                        keyRotation: item.item.keyRotation,
                                        content: item.item.content,
                                        itemKey: item.item.itemKey,
                                        state: modifiedItem.state,
                                        pinned: item.item.pinned,
                                        pinTime: item.item.pinTime,
                                        aliasEmail: item.item.aliasEmail,
                                        createTime: item.item.createTime,
                                        modifyTime: modifiedItem.modifyTime,
                                        lastUseTime: item.item.lastUseTime,
                                        revisionTime: modifiedItem.revisionTime,
                                        flags: modifiedItem.flags)
                try await upsertItems([.init(shareId: item.shareId,
                                             userId: item.userId,
                                             item: modifiedItem,
                                             encryptedContent: item.encryptedContent,
                                             isLogInItem: item.isLogInItem)])
            }
        }
    }

    func update(lastUseItems: [LastUseItem], shareId: String) async throws {
        let taskContext = newTaskContext(type: .fetch)
        try taskContext.performAndWait {
            for item in lastUseItems {
                let fetchRequest: NSFetchRequest<ItemEntity> = ItemEntity.fetchRequest()
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    NSPredicate(format: "shareID = %@", shareId),
                    NSPredicate(format: "itemID = %@", item.itemID)
                ])
                let results = try taskContext.fetch(fetchRequest)
                if let fetchedItem = results.first {
                    fetchedItem.lastUseTime = Int64(item.lastUseTime)
                }
            }
            if taskContext.hasChanges {
                try taskContext.save()
            }
        }
    }

    func deleteItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        for item in items {
            try await deleteItems(itemIds: [item.item.itemID], shareId: item.shareId)
        }
    }

    func deleteItems(itemIds: [String], shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        for itemId in itemIds {
            let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ItemEntity")
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                .init(format: "shareID = %@", shareId),
                .init(format: "itemID = %@", itemId)
            ])
            try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                              context: taskContext)
        }
    }

    func removeAllItems() async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ItemEntity")
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func removeAllItems(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ItemEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func removeAllItems(shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ItemEntity")
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func getActiveLogInItems(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "userID = %@", userId),
            .init(format: "state = %d", ItemState.active.rawValue),
            .init(format: "isLogInItem = %d", true)
        ])
        fetchRequest.sortDescriptors = [.init(key: "modifyTime", ascending: false)]
        let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try itemEntities.map { try $0.toEncryptedItem() }
    }

    func getItems(for items: [any ItemIdentifiable]) async throws -> [SymmetricallyEncryptedItem] {
        // Create an array to hold individual predicates
        var predicates: [NSPredicate] = []

        for item in items {
            let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                .init(format: "shareID = %@", item.shareId),
                .init(format: "itemID = %@", item.itemId)
            ])
            predicates.append(compoundPredicate)
        }

        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)

        // Set the batch size to optimize fetching
        let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try itemEntities.map { try $0.toEncryptedItem() }
    }
}

public extension LocalItemDatasource {
    /// Temporary migration, can be removed after july 2025
    func updateLocalItems(with userId: String) async throws {
        let allItems = try await getAllItems(userId: "")
        let updatedItems = allItems.map { $0.copy(newUserId: userId) }
        try await removeAllItems(userId: "")
        try await upsertItems(updatedItems)
    }
}

private extension SymmetricallyEncryptedItem {
    func copy(newUserId: String) -> SymmetricallyEncryptedItem {
        SymmetricallyEncryptedItem(shareId: shareId,
                                   userId: newUserId,
                                   item: item,
                                   encryptedContent: encryptedContent,
                                   isLogInItem: isLogInItem)
    }
}
