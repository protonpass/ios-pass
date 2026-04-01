//
// LocalFolderKeyDatasource.swift
// Proton Pass - Created on 10/12/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import Foundation

// sourcery: AutoMockable
public protocol LocalFolderKeyDatasourceProtocol: Sendable {
    func getAllFolderKeys() async throws -> [SymmetricallyEncryptedFolderKey]
    // periphery:ignore
    func getAllFolderKeys(userId: String) async throws -> [SymmetricallyEncryptedFolderKey]
    func upsertFolderKeys(_ keys: [SymmetricallyEncryptedFolderKey]) async throws
    // periphery:ignore
    func getFolderKeys(userId: String,
                       shareId: String,
                       folderId: String) async throws -> [SymmetricallyEncryptedFolderKey]
    func removeAllKeys(userId: String) async throws
}

public final class LocalFolderKeyDatasource: LocalDatasource, LocalFolderKeyDatasourceProtocol,
    @unchecked Sendable {}

public extension LocalFolderKeyDatasource {
    func getAllFolderKeys() async throws -> [SymmetricallyEncryptedFolderKey] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = FolderKeyEntity.fetchRequest()
        let folderEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return folderEntities.map { $0.toSymmetricallyEncryptedKey() }
    }

    func getAllFolderKeys(userId: String) async throws -> [SymmetricallyEncryptedFolderKey] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = FolderKeyEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let folderEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return folderEntities.map { $0.toSymmetricallyEncryptedKey() }
    }

    func getFolderKeys(userId: String,
                       shareId: String,
                       folderId: String) async throws -> [SymmetricallyEncryptedFolderKey] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = FolderKeyEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "shareID = %@", shareId),
            .init(format: "userID = %@", userId),
            .init(format: "folderID = %@", folderId)
        ])
        let folderEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return folderEntities.map { $0.toSymmetricallyEncryptedKey() }
    }

    func upsertFolderKeys(_ keys: [SymmetricallyEncryptedFolderKey]) async throws {
        try await upsert(keys,
                         entityType: FolderKeyEntity.self,
                         fetchPredicate: NSPredicate(format: "folderID IN %@ AND shareID IN %@ AND userID IN %@ AND keyRotation IN %@", // swiftlint:disable:this line_length
                                                     keys.map(\.folderId),
                                                     keys.map(\.shareId),
                                                     keys.map(\.userId),
                                                     keys.map(\.keyRotation)),
                         isEqual: { key, entity in
                             key.folderId == entity.folderID &&
                                 key.userId == entity.userID &&
                                 key.shareId == entity.shareID &&
                                 key.keyRotation == entity.keyRotation
                         }, hydrate: { folder, entity in
                             entity.hydrate(from: folder)
                         })
    }

    func removeAllKeys(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "FolderKeyEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
