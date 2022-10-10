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

public protocol LocalItemDatasourceProtocol: LocalDatasourceProtocol {
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
    func deleteItems(_ items: [SymmetricallyEncryptedItem]) async throws

    /// Nuke items of a share
    func removeAllItems(shareId: String) async throws
}

public extension LocalItemDatasourceProtocol {
    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem? {
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

    func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
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

    func getItemCount(shareId: String) async throws -> Int {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ItemEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        return try await count(fetchRequest: fetchRequest, context: taskContext)
    }

    func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let taskContext = newTaskContext(type: .insert)
        let entity = ItemEntity.entity(context: taskContext)
        let batchInsertRequest = newBatchInsertRequest(entity: entity,
                                                       sourceItems: items) { managedObject, item in
            (managedObject as? ItemEntity)?.hydrate(from: item)
        }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    func upsertItems(_ items: [SymmetricallyEncryptedItem],
                     modifiedItems: [ModifiedItem]) async throws {
        for item in items {
            if let modifiedItem = modifiedItems.first(where: { $0.itemID == item.item.itemID }) {
                let modifiedItem = ItemRevision(itemID: item.item.itemID,
                                                revision: modifiedItem.revision,
                                                contentFormatVersion: item.item.contentFormatVersion,
                                                rotationID: item.item.rotationID,
                                                content: item.item.content,
                                                userSignature: item.item.userSignature,
                                                itemKeySignature: item.item.itemKeySignature,
                                                state: modifiedItem.state,
                                                signatureEmail: item.item.signatureEmail,
                                                aliasEmail: item.item.aliasEmail,
                                                createTime: item.item.createTime,
                                                modifyTime: modifiedItem.modifyTime,
                                                revisionTime: modifiedItem.revisionTime)
                try await upsertItems([.init(shareId: item.shareId,
                                             item: modifiedItem,
                                             encryptedContent: item.encryptedContent,
                                             isLogInItem: item.isLogInItem)])
            }
        }
    }

    func deleteItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let taskContext = newTaskContext(type: .delete)
        for item in items {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ItemEntity")
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                .init(format: "shareID = %@", item.shareId),
                .init(format: "itemID = %@", item.item.itemID)
            ])
            try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                              context: taskContext)
        }
    }

    func removeAllItems(shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ItemEntity")
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}

public final class LocalItemDatasource: LocalDatasource, LocalItemDatasourceProtocol {}
