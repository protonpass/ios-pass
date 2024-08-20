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

public final class LocalItemDatasource: LocalDatasource, LocalItemDatasourceProtocol {}

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

//    func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
//        let taskContext = newTaskContext(type: .insert)
//        let entity = ItemEntity.entity(context: taskContext)
//        let batchInsertRequest = newBatchInsertRequest(entity: entity,
//                                                       sourceItems: items) { managedObject, item in
//            (managedObject as? ItemEntity)?.hydrate(from: item)
//        }
//        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
//    }

    func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        try await upsertElements(items: items,
                                 fetchPredicate: NSPredicate(format: "itemID IN %@ AND shareID IN %@",
                                                             items.map(\.item.itemID),
                                                             items.map(\.shareId)),
                                 itemComparisonKey: { item in
            ItemKeyComparison(itemID: item.item.itemID, shareID: item.shareId)
                                 },
                                 entityComparisonKey: { entity in
            ItemKeyComparison(itemID: entity.itemID, shareID: entity.shareID)
                                 },
                                 updateEntity: { [weak self] (entity: ItemEntity,
                                                              item: SymmetricallyEncryptedItem) in
                                         guard let self else { return }
                                         updateEntity(entity, with: item)
                                 },
                                 insertItems: insertItems)
    }

 

//
//

//    func newBatchUpdateRequest<T>(entity: NSEntityDescription,
//                                  sourceItems: [T],
//                                  hydrateBlock: @escaping (NSManagedObject, T) -> Void)
//        -> NSBatchInsertRequest {
//        var index = 0
//        let request = NSBatchUpdateRequest(entity: <#T##NSEntityDescription#>)
//
//            NSBatchInsertRequest(entity: entity,
//                                           managedObjectHandler: { object in
//                                               guard index < sourceItems.count else { return true }
//                                               let item = sourceItems[index]
//                                               hydrateBlock(object, item)
//                                               index += 1
//                                               return false
//                                           })
//        return request
//    }

    // ############################

//    private func updateItems(_ items: [SymmetricallyEncryptedItem]) async throws {
//         let taskContext = newTaskContext(type: .insert)
//         let entity = ItemEntity.entity(context: taskContext)
//        for item in itemsToUpdate {
//            let updateRequest = NSBatchUpdateRequest(entityName: "ItemEntity")
//            updateRequest.predicate = NSPredicate(format: "itemID == %@", item.itemId)
//            updateRequest.propertiesToUpdate = [
//                "aliasEmail": item.item.aliasEmail,
//                "content": item.item.content,
//                "contentFormatVersion": item.item.contentFormatVersion,
//                "createTime": item.item.createTime,
//                "isLogInItem": item.isLogInItem,
//                "itemID": item.item.itemID,
//                "itemKey": item.item.itemKey,
//                "keyRotation": item.item.keyRotation,
//                "lastUseTime": item.item.lastUseTime ?? 0,
//                "modifyTime": item.item.modifyTime,
//                "revision": item.item.revision,
//                "revisionTime": item.item.revision,
//                "shareID": item.shareId,
//                "state": item.item.state,
//                "pinned": item.item.pinned,
//                "pinTime": item.item.pinTime,
//                "symmetricallyEncryptedContent": item.encryptedContent,
//                "flags": item.item.flags
//            ]
//        }
//
    ////         let batchInsertRequest = newBatchInsertRequest(entity: entity,
    ////                                                        sourceItems: items) { managedObject, item in
    ////             (managedObject as? ItemEntity)?.hydrate(from: item)
    ////         }
//         try await execute(batchUpdateRequest: batchInsertRequest, context: taskContext)
//     }
//
//    @objc(ItemEntity)
//    final class ItemEntity: NSManagedObject {}
//
//    extension ItemEntity: Identifiable {}
//
//    extension ItemEntity {
//        @nonobjc
//        public class func fetchRequest() -> NSFetchRequest<ItemEntity> {
//            NSFetchRequest<ItemEntity>(entityName: "ItemEntity")
//        }
//
//        @NSManaged var aliasEmail: String?
//        @NSManaged var content: String?
//        @NSManaged var contentFormatVersion: Int64
//        @NSManaged var createTime: Int64
//        @NSManaged var isLogInItem: Bool // Custom field
//        @NSManaged var itemID: String?
//        @NSManaged var itemKey: String?
//        @NSManaged var keyRotation: Int64
//        @NSManaged var lastUseTime: Int64
//        @NSManaged var modifyTime: Int64
//        @NSManaged var revision: Int64
//        @NSManaged var revisionTime: Int64
//        @NSManaged var shareID: String? // Custom field
//        @NSManaged var state: Int64
//        @NSManaged var pinned: Bool
//        @NSManaged var pinTime: Int64
//        @NSManaged var symmetricallyEncryptedContent: String? // Custom field
//        @NSManaged var flags: Int64
//        @NSManaged var userID: String
//    }
//
//    extension ItemEntity {
//        func toEncryptedItem() throws -> SymmetricallyEncryptedItem {
//            guard let shareID else {
//                throw PassError.coreData(.corrupted(object: self, property: "shareID"))
//            }
//
//            guard let itemID else {
//                throw PassError.coreData(.corrupted(object: self, property: "itemID"))
//            }
//
//            guard let symmetricallyEncryptedContent else {
//                throw PassError.coreData(.corrupted(object: self,
//                                                    property: "symmetricallyEncryptedContent"))
//            }
//
//            guard let content else {
//                throw PassError.coreData(.corrupted(object: self, property: "content"))
//            }
//
//            let item = Item(itemID: itemID,
//                            revision: revision,
//                            contentFormatVersion: contentFormatVersion,
//                            keyRotation: keyRotation,
//                            content: content,
//                            itemKey: itemKey,
//                            state: state,
//                            pinned: pinned,
//                            pinTime: pinTime == 0 ? nil : Int(pinTime),
//                            aliasEmail: aliasEmail,
//                            createTime: createTime,
//                            modifyTime: modifyTime,
//                            lastUseTime: lastUseTime == 0 ? nil : lastUseTime,
//                            revisionTime: revisionTime,
//                            flags: Int(flags))
//
//            return .init(shareId: shareID,
//                         userId: userID,
//                         item: item,
//                         encryptedContent: symmetricallyEncryptedContent,
//                         isLogInItem: isLogInItem)
//        }
//
//        func hydrate(from symmetricallyEncryptedItem: SymmetricallyEncryptedItem) {
//            let item = symmetricallyEncryptedItem.item
//            aliasEmail = item.aliasEmail
//            content = item.content
//            contentFormatVersion = item.contentFormatVersion
//            createTime = item.createTime
//            isLogInItem = symmetricallyEncryptedItem.isLogInItem
//            itemID = item.itemID
//            itemKey = item.itemKey
//            keyRotation = item.keyRotation
//            lastUseTime = item.lastUseTime ?? 0
//            modifyTime = item.modifyTime
//            pinned = item.pinned
//            revision = item.revision
//            revisionTime = item.revisionTime
//            shareID = symmetricallyEncryptedItem.shareId
//            userID = symmetricallyEncryptedItem.userId
//            state = item.state
//            symmetricallyEncryptedContent = symmetricallyEncryptedItem.encryptedContent
//            flags = Int64(item.flags)
//        }
//    }

//    func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
//        let context = newTaskContext(type: .insert)
//        try await context.perform {
//            let itemIDs = items.map(\.itemId)
//
//            // 1. Fetch existing items with matching IDs
//            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ItemEntity")
//            fetchRequest.predicate = NSPredicate(format: "itemID IN %@", itemIDs)
//            let existingItems = try context.fetch(fetchRequest)
//
//            var itemsToUpdate: [SymmetricallyEncryptedItem] = []
//            var existingItemIDs = Set<String>()
//
//            for item in existingItems {
//                if let id = item.value(forKey: "itemID") as? String {
//                    existingItemIDs.insert(id)
//                }
//            }
//
//            // 2. Determine items to insert or update
//            var itemsToInsert: [[String: Any]] = []
//
//            for item in items {
//                if existingItemIDs.contains(item.itemId) {
//                    itemsToUpdate.append(item)
//                } else {
//                    let entityInfo: [String: Any] = [
//                        "aliasEmail": item.item.aliasEmail,
//                        "content": item.item.content,
//                        "contentFormatVersion": item.item.contentFormatVersion,
//                        "createTime": item.item.createTime,
//                        "isLogInItem": item.isLogInItem,
//                        "itemID": item.item.itemID,
//                        "itemKey": item.item.itemKey,
//                        "keyRotation": item.item.keyRotation,
//                        "lastUseTime": item.item.lastUseTime ?? 0,
//                        "modifyTime": item.item.modifyTime,
//                        "revision": item.item.revision,
//                        "revisionTime": item.item.revisionTime,
//                        "shareID": item.shareId,
//                        "state": item.item.state,
//                        "pinned": item.item.pinned,
//                        "pinTime": Int64(item.item.pinTime ?? 0),
//                        "symmetricallyEncryptedContent": item.encryptedContent,
//                        "flags": Int64(item.item.flags)
//                    ]
//                    //                var entity = ItemEntity()
//                    //                entity.hydrate(from: item)
//                    itemsToInsert.append(entityInfo)
//                }
//            }
//
//            // 3. Perform batch insert for new items
//            if !itemsToInsert.isEmpty {
//                let insertRequest = NSBatchInsertRequest(entityName: "ItemEntity", objects: itemsToInsert)
//                try context.execute(insertRequest)
//            }
//
//            // 4. Perform batch update for existing items
//            for item in itemsToUpdate {
//                let updateRequest = NSBatchUpdateRequest(entityName: "ItemEntity")
//                updateRequest.predicate = NSPredicate(format: "itemID == %@", item.itemId)
//                updateRequest.propertiesToUpdate = [
//                    "aliasEmail": item.item.aliasEmail,
//                    "content": item.item.content,
//                    "contentFormatVersion": item.item.contentFormatVersion,
//                    "createTime": item.item.createTime,
//                    "isLogInItem": item.isLogInItem,
//                    "itemID": item.item.itemID,
//                    "itemKey": item.item.itemKey,
//                    "keyRotation": item.item.keyRotation,
//                    "lastUseTime": item.item.lastUseTime ?? 0,
//                    "modifyTime": item.item.modifyTime,
//                    "revision": item.item.revision,
//                    "revisionTime": item.item.revision,
//                    "shareID": item.shareId,
//                    "state": item.item.state,
//                    "pinned": item.item.pinned,
//                    "pinTime": Int64(item.item.pinTime ?? 0),
//                    "symmetricallyEncryptedContent": item.encryptedContent,
//                    "flags": Int64(item.item.flags)
//                ]
//                updateRequest.resultType = .statusOnlyResultType
//
//                try context.execute(updateRequest)
//            }
//
//            // 5. Save context if needed
//            //            if context.hasChanges {
//            try context.save()
//            //            }
//        }
//    }

    // ############################

//    func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
//        let context = newTaskContext(type: .insert)
//
//        let batchSize = 1_000
//        let itemIDs = items.map(\.itemId)
//
//        var existingItemIDs = Set<String>()
//
//        // 1. Batch fetch existing IDs
//        for batch in stride(from: 0, to: itemIDs.count, by: batchSize) {
//            let batchIDs = Array(itemIDs[batch..<min(batch + batchSize, itemIDs.count)])
//            let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ItemEntity")
    ////            fetchRequest.predicate = NSPredicate(format: "itemID IN %@", batchIDs)
//            fetchRequest.resultType = .managedObjectResultType
//
//            let entities = try context.fetch(fetchRequest)
//            print(entities)
    ////
    ////            existingItemIDs.formUnion(objectIDs.compactMap {
    ////                context.object(with: $0).value(forKey: "itemID") as? String
    ////            })
//        }
//
    ////
    ////        let item = symmetricallyEncryptedItem.item
    ////        aliasEmail = item.aliasEmail
    ////        content = item.content
    ////        contentFormatVersion = item.contentFormatVersion
    ////        createTime = item.createTime
    ////        isLogInItem = symmetricallyEncryptedItem.isLogInItem
    ////        itemID = item.itemID
    ////        itemKey = item.itemKey
    ////        keyRotation = item.keyRotation
    ////        lastUseTime = item.lastUseTime ?? 0
    ////        modifyTime = item.modifyTime
    ////        pinned = item.pinned
    ////        revision = item.revision
    ////        revisionTime = item.revisionTime
    ////        shareID = symmetricallyEncryptedItem.shareId
    ////        userID = symmetricallyEncryptedItem.userId
    ////        state = item.state
    ////        symmetricallyEncryptedContent = symmetricallyEncryptedItem.encryptedContent
    ////        flags = Int64(item.flags)
//
//        // 2. Split data for insert and update
//        var itemsToInsert: [[String: Any]] = []
//        var itemsToUpdate: [(id: String, properties: [String: Any])] = []
//
//        for item in items {
//            if existingItemIDs.contains(item.itemId) {
//                itemsToUpdate.append((id: item.itemId, properties: [
//                    "aliasEmail": item.item.aliasEmail,
//                    "content": item.item.content,
//                    "contentFormatVersion": item.item.contentFormatVersion,
//                    "createTime": item.item.createTime,
//                    "isLogInItem": item.isLogInItem,
//                    "itemID": item.item.itemID,
//                    "itemKey": item.item.itemKey,
//                    "keyRotation": item.item.keyRotation,
//                    "lastUseTime": item.item.lastUseTime ?? 0,
//                    "modifyTime": item.item.modifyTime,
//                    "revision": item.item.revision,
//                    "revisionTime": item.item.revision,
//                    "shareID": item.shareId,
//                    "state": item.item.state,
//                    "pinned": item.item.pinned,
//                    "pinTime": item.item.pinTime,
//                    "symmetricallyEncryptedContent": item.encryptedContent,
//                    "flags": item.item.flags
//                ]))
//            } else {
//                itemsToInsert.append([
//                    "aliasEmail": item.item.aliasEmail,
//                    "content": item.item.content,
//                    "contentFormatVersion": item.item.contentFormatVersion,
//                    "createTime": item.item.createTime,
//                    "isLogInItem": item.isLogInItem,
//                    "itemID": item.item.itemID,
//                    "itemKey": item.item.itemKey,
//                    "keyRotation": item.item.keyRotation,
//                    "lastUseTime": item.item.lastUseTime ?? 0,
//                    "modifyTime": item.item.modifyTime,
//                    "revision": item.item.revision,
//                    "revisionTime": item.item.revision,
//                    "shareID": item.shareId,
//                    "state": item.item.state,
//                    "pinned": item.item.pinned,
//                    "pinTime": item.item.pinTime,
//                    "symmetricallyEncryptedContent": item.encryptedContent,
//                    "flags": item.item.flags
//                ])
//            }
//        }
//
//        // 3. Batch insert new items
//        if !itemsToInsert.isEmpty {
//            let insertRequest = NSBatchInsertRequest(entityName: "ItemEntity", objects: itemsToInsert)
//            try context.execute(insertRequest)
//        }
//
//        // 4. Batch update existing items
    ////        for update in itemsToUpdate.chunked(into: batchSize) {
    ////            let updateRequest = NSBatchUpdateRequest(entityName: "ItemEntity")
    ////            updateRequest.predicate = NSPredicate(format: "itemID IN %@", update.map { $0.id })
    ////            updateRequest.propertiesToUpdate = update.map { $0.properties }
//        ////            update.reduce(into: [String: Any]()) { dict, item in
//        ////                dict["aliasEmail"] = item.properties["aliasEmail"]
//        ////                dict["content"] = item.properties["content"]
//        ////                dict["name"] = item.properties["name"]
//        ////                dict["value"] = item.properties["value"]
//        ////                dict["name"] = item.properties["name"]
//        ////                dict["value"] = item.properties["value"]
//        ////                dict["name"] = item.properties["name"]
//        ////                dict["value"] = item.properties["value"]
//        ////                dict["name"] = item.properties["name"]
//        ////                dict["value"] = item.properties["value"]
//        ////                dict["name"] = item.properties["name"]
//        ////                dict["value"] = item.properties["value"]
//        ////                dict["name"] = item.properties["name"]
//        ////                dict["value"] = item.properties["value"]
//        ////                dict["name"] = item.properties["name"]
//        ////                dict["value"] = item.properties["value"]
//        ////                dict["name"] = item.properties["name"]
//        ////                dict["value"] = item.properties["value"]
//        ////                [
//        ////                    "aliasEmail": item.item.aliasEmail,
//        ////                    "content": item.item.content,
//        ////                    "contentFormatVersion": item.item.contentFormatVersion,
//        ////                    "createTime": item.item.createTime,
//        ////                    "isLogInItem": item.isLogInItem,
//        ////                    "itemID": item.item.itemID,
//        ////                    "itemKey": item.item.itemKey,
//        ////                    "keyRotation": item.item.keyRotation,
//        ////                    "lastUseTime": item.item.lastUseTime ?? 0,
//        ////                    "modifyTime": item.item.modifyTime,
//        ////                    "revision": item.item.revision,
//        ////                    "revisionTime": item.item.revision,
//        ////                    "shareID": item.shareId,
//        ////                    "state": item.item.state,
//        ////                    "pinned": item.item.pinned,
//        ////                    "pinTime": item.item.pinTime,
//        ////                    "symmetricallyEncryptedContent": item.encryptedContent,
//        ////                    "flags": item.item.flags
//        ////                ]
//        ////            }
    ////            updateRequest.resultType = .updatedObjectsCountResultType
    ////
    ////            try context.execute(updateRequest)
    ////        }
//        try batchUpdateItems(itemsToUpdate: itemsToUpdate, context: context)
//
//        // 5. Save context if needed
//        if context.hasChanges {
//            try context.save()
//        }
//    }

//    func batchUpdateItems(itemsToUpdate: [(id: String, properties: [String: Any])],
//                          context: NSManagedObjectContext) throws {
//        let batchSize = 1_000
//
//        // Iterate over items in chunks to avoid excessive memory usage
//        for batch in itemsToUpdate.chunked(into: batchSize) {
//            for item in batch {
//                let updateRequest = NSBatchUpdateRequest(entityName: "Item")
//                updateRequest.predicate = NSPredicate(format: "id == %@", item.id)
//                updateRequest.propertiesToUpdate = item.properties
//                updateRequest.resultType = .updatedObjectsCountResultType
//
//                // Execute the update request
//                let updateResult = try context.execute(updateRequest) as? NSBatchUpdateResult
//                if let updatedCount = updateResult?.result as? Int {
//                    print("Updated \(updatedCount) records for ID \(item.id).")
//                }
//            }
//        }
//    }

//    func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
//        let context = newTaskContext(type: .insert)
//
//        let itemIDs = items.map { $0.itemId }
//
//        // 1. Fetch existing items with matching IDs
//        let fetchRequest: NSFetchRequest<NSManagedObject> = NSFetchRequest(entityName: "ItemEntity")
//        fetchRequest.predicate = NSPredicate(format: "itemID IN %@", itemIDs)
//        let existingItems = try context.fetch(fetchRequest)
//
//        var itemsToUpdate: [ItemEntity] = []
//        var existingItemIDs = Set<String>()
//
//        for item in existingItems {
//            if let id = item.value(forKey: "id") as? String {
//                existingItemIDs.insert(id)
//            }
//        }
//
//        // 2. Determine items to insert or update
//        var itemsToInsert: [[String: Any]] = []
//        for item in items {
//            if existingItemIDs.contains(item.id) {
//                itemsToUpdate.append(item)
//            } else {
//                ItemEntity.hydrate(<#T##self: ItemEntity##ItemEntity#>)
//            }
//        }
//
//        // 3. Perform batch insert for new items
//        if !itemsToInsert.isEmpty {
//            let insertRequest = NSBatchInsertRequest(entityName: "Item", objects: itemsToInsert)
//            try context.execute(insertRequest)
//        }
//
//        // 4. Perform batch update for existing items
//        for item in itemsToUpdate {
//            let updateRequest = NSBatchUpdateRequest(entityName: "Item")
//            updateRequest.predicate = NSPredicate(format: "id == %@", item.id)
//            updateRequest.propertiesToUpdate = [
//                "name": item.name,
//                "value": item.value
//            ]
//            updateRequest.resultType = .updatedObjectsCountResultType
//
//            try context.execute(updateRequest)
//        }
//
//        // 5. Save context if needed
//        if context.hasChanges {
//            try context.save()
//        }
//    }

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
                                        flags: item.item.flags)
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

// MARK: - upset utils
private extension LocalItemDatasource {
    struct ItemKeyComparison: Hashable {
        let itemID: String
        let shareID: String
    }
    
    func insertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        let taskContext = newTaskContext(type: .insert)
        let entity = ItemEntity.entity(context: taskContext)
        let batchInsertRequest = newBatchInsertRequest(entity: entity,
                                                       sourceItems: items) { managedObject, item in
            (managedObject as? ItemEntity)?.hydrate(from: item)
        }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }
    
    func updateEntity(_ entity: ItemEntity, with newItem: SymmetricallyEncryptedItem) {
        let newItemData = newItem.item

        if entity.aliasEmail != newItemData.aliasEmail {
            entity.aliasEmail = newItemData.aliasEmail
        }
        if entity.content != newItemData.content {
            entity.content = newItemData.content
        }
        if entity.contentFormatVersion != newItemData.contentFormatVersion {
            entity.contentFormatVersion = newItemData.contentFormatVersion
        }
        if entity.createTime != newItemData.createTime {
            entity.createTime = newItemData.createTime
        }
        if entity.isLogInItem != newItem.isLogInItem {
            entity.isLogInItem = newItem.isLogInItem
        }
        if entity.itemKey != newItemData.itemKey {
            entity.itemKey = newItemData.itemKey
        }
        if entity.keyRotation != newItemData.keyRotation {
            entity.keyRotation = newItemData.keyRotation
        }
        if entity.lastUseTime != newItemData.lastUseTime {
            entity.lastUseTime = newItemData.lastUseTime ?? 0
        }
        if entity.modifyTime != newItemData.modifyTime {
            entity.modifyTime = newItemData.modifyTime
        }
        if entity.pinned != newItemData.pinned {
            entity.pinned = newItemData.pinned
        }
        if entity.revision != newItemData.revision {
            entity.revision = newItemData.revision
        }
        if entity.revisionTime != newItemData.revisionTime {
            entity.revisionTime = newItemData.revisionTime
        }
        if entity.shareID != newItem.shareId {
            entity.shareID = newItem.shareId
        }
        if entity.userID != newItem.userId {
            entity.userID = newItem.userId
        }
        if entity.state != newItemData.state {
            entity.state = newItemData.state
        }
        if entity.symmetricallyEncryptedContent != newItem.encryptedContent {
            entity.symmetricallyEncryptedContent = newItem.encryptedContent
        }
        if entity.flags != Int64(newItemData.flags) {
            entity.flags = Int64(newItemData.flags)
        }
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

//extension Array {
//    /// Splits the array into chunks of a specified size.
//    func chunked(into size: Int) -> [[Element]] {
//        stride(from: 0, to: count, by: size).map {
//            Array(self[$0..<Swift.min($0 + size, count)])
//        }
//    }
//}
