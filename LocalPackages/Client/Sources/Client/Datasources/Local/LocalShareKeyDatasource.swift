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

public final class LocalShareKeyDatasource: LocalDatasource, LocalShareKeyDatasourceProtocol,
    @unchecked Sendable {}

public extension LocalShareKeyDatasource {
    func getKeys(shareId: String) async throws -> [SymmetricallyEncryptedShareKey] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ShareKeyEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.map { $0.toSymmetricallyEncryptedShareKey() }
    }

    func upsertKeys(_ keys: [SymmetricallyEncryptedShareKey]) async throws {
        try await upsert(keys,
                         entityType: ShareKeyEntity.self,
                         fetchPredicate: NSPredicate(format: "shareID IN %@ AND keyRotation IN %@",
                                                     keys.map(\.shareId),
                                                     keys.map(\.shareKey.keyRotation)),
                         isEqual: { item, entity in
                             item.shareId == entity.shareID && item.shareKey.keyRotation == entity.keyRotation
                         },
                         hydrate: { item, entity in
                             entity.hydrate(from: item)
                         })
    }

    func removeAllKeys(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ShareKeyEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
