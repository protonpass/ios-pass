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

    /// Remove all keys of a share
    func removeAllKeys(shareId: String) async throws

    /// Remove all keys for all shares
    func removeAllKeys() async throws
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
        let taskContext = newTaskContext(type: .insert)
        let batchInsertRequest =
            newBatchInsertRequest(entity: ShareKeyEntity.entity(context: taskContext),
                                  sourceItems: keys) { managedObject, key in
                (managedObject as? ShareKeyEntity)?.hydrate(from: key)
            }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    func removeAllKeys(shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ShareKeyEntity")
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func removeAllKeys() async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ShareKeyEntity")
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
