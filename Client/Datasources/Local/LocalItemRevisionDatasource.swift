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
    /// Get a specific item revision
    func getItemRevision(shareId: String, itemId: String) async throws -> ItemRevision?

    /// Get item revisions by state (active/trashed)
    func getItemRevisions(shareId: String, state: ItemRevisionState) async throws -> [ItemRevision]

    /// Get total item revisions of a share (both active and trashed ones)
    func getItemRevisionCount(shareId: String) async throws -> Int

    /// Insert or update a list of item revisions
    func upsertItemRevisions(_ items: [ItemRevision], shareId: String) async throws

    /// Nuke item revisions of a share
    func removeAllItemRevisions(shareId: String) async throws

    /// Send  item revisions to trash
    func trashItemRevisions(_ items: [ItemRevision],
                            modifiedItems: [ModifiedItem],
                            shareId: String) async throws

    /// Permanently delete item revisions
    func deleteItemRevisions(_ items: [ItemRevision], shareId: String) async throws
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

    public func getItemRevisions(shareId: String, state: ItemRevisionState) async throws -> [ItemRevision] {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = ItemRevisionEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "shareID = %@", shareId),
            .init(format: "state = %d", state.rawValue)
        ])
        fetchRequest.sortDescriptors = [.init(key: "modifyTime", ascending: false)]
        let itemRevisionEntities = try await execute(fetchRequest: fetchRequest,
                                                     context: taskContext)
        return try itemRevisionEntities.map { try $0.toItemRevision() }
    }

    public func getItemRevisionCount(shareId: String) async throws -> Int {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = ItemRevisionEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        return try await count(fetchRequest: fetchRequest, context: taskContext)
    }

    public func upsertItemRevisions(_ items: [ItemRevision],
                                    shareId: String) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
        newBatchInsertRequest(entity: ItemRevisionEntity.entity(context: taskContext),
                              sourceItems: items) { managedObject, itemRevision in
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

    public func trashItemRevisions(_ items: [ItemRevision],
                                   modifiedItems: [ModifiedItem],
                                   shareId: String) async throws {
        for item in items {
            if let modifiedItem = modifiedItems.first(where: { $0.itemID == item.itemID }) {
                let trashedItem = ItemRevision(itemID: item.itemID,
                                               revision: modifiedItem.revision,
                                               contentFormatVersion: item.contentFormatVersion,
                                               rotationID: item.rotationID,
                                               content: item.content,
                                               userSignature: item.userSignature,
                                               itemKeySignature: item.itemKeySignature,
                                               state: modifiedItem.state,
                                               signatureEmail: item.signatureEmail,
                                               aliasEmail: item.aliasEmail,
                                               createTime: item.createTime,
                                               modifyTime: modifiedItem.modifyTime,
                                               revisionTime: modifiedItem.revisionTime)
                try await upsertItemRevisions([trashedItem], shareId: shareId)
            }
        }
    }

    public func deleteItemRevisions(_ items: [ItemRevision], shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)

        for item in items {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ItemRevisionEntity")
            fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                .init(format: "shareID = %@", shareId),
                .init(format: "itemID = %@", item.itemID)
            ])
            try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                              context: taskContext)
        }
    }
}
