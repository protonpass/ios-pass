//
// LocalShareKeyDatasource.swift
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

public protocol LocalShareKeyDatasourceProtocol: Sendable {
    /// Get keys of a share
    func getKeys(shareId: String) async throws -> [SymmetricallyEncryptedShareKey]

    /// Insert or update if exist keys
    func upsertKeys(_ keys: [SymmetricallyEncryptedShareKey]) async throws

    /// Remove all keys for all shares related to a user
    func removeAllKeys(userId: String) async throws
}

public final class LocalShareKeyDatasource: LocalDatasource, LocalShareKeyDatasourceProtocol {}

public extension LocalShareKeyDatasource {
    func getKeys(shareId: String) async throws -> [SymmetricallyEncryptedShareKey] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ShareKeyEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.map { $0.toSymmetricallyEncryptedShareKey() }
    }

    func upsertKeys(_ keys: [SymmetricallyEncryptedShareKey]) async throws {
        try await upsert(items: keys,
                         fetchPredicate: NSPredicate(format: "shareID IN %@ AND keyRotation IN %@",
                                                     keys.map(\.shareId),
                                                     keys.map(\.shareKey.keyRotation)),
                         itemComparisonKey: { item in
                             ShareKeyComparison(shareID: item.shareId,
                                                keyRotation: item.shareKey.keyRotation)
                         },
                         entityComparisonKey: { entity in
                             ShareKeyComparison(shareID: entity.shareID, keyRotation: entity.keyRotation)
                         },
                         updateEntity: { (entity: ShareKeyEntity, key: SymmetricallyEncryptedShareKey) in
                             entity.hydrate(from: key)
                         },
                         insertItems: { [weak self] keys, context in
                             guard let self else { return }
                             try await insert(keys, context: context)
                         })
    }

    func removeAllKeys(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ShareKeyEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    /// Temporary migration, can be removed after july 2025
    func updateKeys(with userId: String) async throws {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ShareKeyEntity.fetchRequest()
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        let keys = entities.map { $0.toSymmetricallyEncryptedShareKey() }

        try await removeAllKeys(userId: "")
        let updatedKeys = keys.map { SymmetricallyEncryptedShareKey(encryptedKey: $0.encryptedKey,
                                                                    shareId: $0.shareId,
                                                                    userId: userId,
                                                                    shareKey: $0.shareKey) }
        try await upsertKeys(updatedKeys)
    }
}

private extension LocalShareKeyDatasource {
    struct ShareKeyComparison: Hashable {
        let shareID: String
        let keyRotation: Int64
    }

    func insert(_ keys: [SymmetricallyEncryptedShareKey], context: NSManagedObjectContext) async throws {
        let batchInsertRequest =
            newBatchInsertRequest(entity: ShareKeyEntity.entity(context: context),
                                  sourceItems: keys) { managedObject, key in
                (managedObject as? ShareKeyEntity)?.hydrate(from: key)
            }
        try await execute(batchInsertRequest: batchInsertRequest, context: context)
    }
}
