//
// LocalFolderDatasource.swift
// Proton Pass - Created on 02/12/2025.
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

// sourcery: AutoMockable
public protocol LocalFolderDatasourceProtocol: Sendable {
    func getAllFolders(userId: String) async throws -> [SymmetricallyEncryptedFolder]
    func getFolder(shareId: String, folderId: String) async throws -> SymmetricallyEncryptedFolder?
    func upsertFolders(_ folders: [SymmetricallyEncryptedFolder]) async throws
    func removeAllFolders() async throws
    func removeAllFolders(userId: String) async throws
    func removeAllFolders(shareId: String) async throws

    func deleteFolders(_ folders: [any ElementIdentifiable]) async throws
    func deleteFolders(folderIds: [String], shareId: String) async throws
}

public final class LocalFolderDatasource: LocalDatasource, LocalFolderDatasourceProtocol, @unchecked Sendable {}

public extension LocalFolderDatasource {
    func getAllFolders(userId: String) async throws -> [SymmetricallyEncryptedFolder] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = FolderEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let folderEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try folderEntities.map { try $0.toEncryptedFolder() }
    }

    func getFolder(shareId: String, folderId: String) async throws -> SymmetricallyEncryptedFolder? {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = FolderEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "shareID = %@", shareId),
            .init(format: "folderID = %@", folderId)
        ])
        let folderEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try folderEntities.first?.toEncryptedFolder()
    }

    func upsertFolders(_ folders: [SymmetricallyEncryptedFolder]) async throws {
        try await upsert(folders,
                         entityType: FolderEntity.self,
                         fetchPredicate: NSPredicate(format: "folderID IN %@ AND shareID IN %@",
                                                     folders.map(\.folderId),
                                                     folders.map(\.shareId)),
                         isEqual: { folder, entity in
                             folder.shareId == entity.shareID && folder.folderId == entity.folderID
                         },
                         hydrate: { folder, entity in
                             try entity.hydrate(from: folder)
                         })
    }

    func deleteFolders(_ folders: [any ElementIdentifiable]) async throws {
        for folder in folders {
            try await deleteFolders(folderIds: [folder.elementId], shareId: folder.shareId)
        }
    }

    func deleteFolders(folderIds: [String], shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "FolderEntity")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "shareID = %@", shareId),
            .init(format: "folderID in %@", folderIds)
        ])
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func removeAllFolders() async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "FolderEntity")
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func removeAllFolders(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "FolderEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func removeAllFolders(shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "FolderEntity")
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
