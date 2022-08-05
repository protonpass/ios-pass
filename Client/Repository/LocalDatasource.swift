//
// LocalDatasource.swift
// Proton Pass - Created on 02/08/2022.
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

import Core
import CoreData

public protocol LocalDatasourceProtocol {
    func insertShares(_ shares: [Share], withUserId userId: String) async throws
    func fetchShares(forUserId userId: String) async throws -> [Share]
    func insertShareKey(_ shareKey: ShareKey, withShareId shareId: String) async throws
    func fetchShareKey(forShareId shareId: String,
                       page: Int,
                       pageSize: Int) async throws -> ShareKey
}

public enum LocalDatasourceError: Error {
    case batchInsertError
}

public final class LocalDatasource {
    let container: NSPersistentContainer

    public init(inMemory: Bool) {
        let container = NSPersistentContainer(name: "Pass")
        if inMemory {
            let description = NSPersistentStoreDescription()
            description.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [description]
        }
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error \(error.localizedDescription)")
            }
        }
        self.container = container
    }

    enum TaskContextType: String {
        case insert = "insertContext"
        case fetch = "fetchContext"
    }

    /// Creates and configures a private queue context.
    private func newTaskContext(type: TaskContextType,
                                transactionAuthor: String) -> NSManagedObjectContext {
        let taskContext = container.newBackgroundContext()
        taskContext.name = type.rawValue
        taskContext.transactionAuthor = transactionAuthor
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }
}

// MARK: - Covenience core data methods
extension LocalDatasource {
    private func execute(batchInsertRequest: NSBatchInsertRequest,
                         withContext context: NSManagedObjectContext) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
            context.performAndWait {
                do {
                    let fetchResult = try context.execute(batchInsertRequest)
                    if let batchInsertResult = fetchResult as? NSBatchInsertResult,
                       let success = batchInsertResult.result as? Bool, success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: LocalDatasourceError.batchInsertError)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func fetch<T>(request: NSFetchRequest<T>,
                          withContext context: NSManagedObjectContext) async throws -> [T] {
        try await withCheckedThrowingContinuation { continuation in
            context.performAndWait {
                do {
                    let result = try context.fetch(request)
                    continuation.resume(with: .success(result))
                } catch {
                    continuation.resume(with: .failure(error))
                }
            }
        }
    }

    private func count<T>(for request: NSFetchRequest<T>,
                          withContext context: NSManagedObjectContext) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            context.performAndWait {
                do {
                    let result = try context.count(for: request)
                    continuation.resume(with: .success(result))
                } catch {
                    continuation.resume(with: .failure(error))
                }
            }
        }
    }
}

// MARK: - LocalDatasourceProtocol
extension LocalDatasource: LocalDatasourceProtocol {
    public func insertShares(_ shares: [Share],
                             withUserId userId: String) async throws {
        let taskContext = newTaskContext(type: .insert,
                                         transactionAuthor: "insertShares")

        var index = 0
        let batchInsertRequest = NSBatchInsertRequest(entity: CDShare.entity(),
                                                      managedObjectHandler: { object in
            guard index < shares.count else { return true }
            let share = shares[index]
            (object as? CDShare)?.copy(from: share, userId: userId)
            index += 1
            return false
        })

        try await execute(batchInsertRequest: batchInsertRequest,
                          withContext: taskContext)
    }

    public func fetchShares(forUserId userId: String) async throws -> [Share] {
        let taskContext = newTaskContext(type: .fetch,
                                         transactionAuthor: "fetchShares")

        let fetchRequest = CDShare.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let cdShares = try await fetch(request: fetchRequest,
                                       withContext: taskContext)
        return try cdShares.map { try $0.toShare() }
    }

    public func insertShareKey(_ shareKey: ShareKey,
                               withShareId shareId: String) async throws {
        try await insertVaultKeys(shareKey.vaultKeys, withShareId: shareId)
        try await insertItemKeys(shareKey.itemKeys, withShareId: shareId)
    }

    func insertVaultKeys(_ vaultKeys: [VaultKey],
                         withShareId shareId: String) async throws {
        let taskContext = newTaskContext(type: .insert,
                                         transactionAuthor: "insertVaultKeys")

        var index = 0
        let batchInsertRequest = NSBatchInsertRequest(entity: CDVaultKey.entity(),
                                                      managedObjectHandler: { object in
            guard index < vaultKeys.count else { return true }
            let vaultKey = vaultKeys[index]
            (object as? CDVaultKey)?.copy(from: vaultKey, shareId: shareId)
            index += 1
            return false
        })
        try await execute(batchInsertRequest: batchInsertRequest, withContext: taskContext)
    }

    func insertItemKeys(_ itemKeys: [ItemKey],
                        withShareId shareId: String) async throws {
        let taskContext = newTaskContext(type: .insert,
                                         transactionAuthor: "insertItemKeys")

        var index = 0
        let batchInsertRequest = NSBatchInsertRequest(entity: CDItemKey.entity(),
                                                      managedObjectHandler: { object in
            guard index < itemKeys.count else { return true }
            let itemKey = itemKeys[index]
            (object as? CDItemKey)?.copy(from: itemKey, shareId: shareId)
            index += 1
            return false
        })
        try await execute(batchInsertRequest: batchInsertRequest, withContext: taskContext)
    }

    public func fetchShareKey(forShareId shareId: String,
                              page: Int,
                              pageSize: Int) async throws -> ShareKey {
        let vaultKeyCount = try await getVaultKeysCount(forShareId: shareId)
        let itemKeyCount = try await getItemKeysCount(forShareId: shareId)

        guard vaultKeyCount == itemKeyCount else {
            throw CoreDataError.corruptedShareKey(shareId)
        }

        let vaultKeys = try await fetchVaultKeys(forShareId: shareId,
                                                 page: page,
                                                 pageSize: pageSize)
        let itemKeys = try await fetchItemKeys(forShareId: shareId,
                                               page: page,
                                               pageSize: pageSize)
        return .init(vaultKeys: vaultKeys,
                     itemKeys: itemKeys,
                     total: vaultKeyCount)
    }

    func fetchVaultKeys(forShareId shareId: String,
                        page: Int,
                        pageSize: Int) async throws -> [VaultKey] {
        let taskContext = newTaskContext(type: .fetch,
                                         transactionAuthor: "fetchVaultKeys")

        let fetchRequest = CDVaultKey.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        fetchRequest.fetchLimit = pageSize
        fetchRequest.fetchOffset = page * pageSize
        let cdVaultKeys = try await fetch(request: fetchRequest,
                                          withContext: taskContext)
        return try cdVaultKeys.map { try $0.toVaultKey() }
    }

    func getVaultKeysCount(forShareId shareId: String) async throws -> Int {
        let taskContext = newTaskContext(type: .fetch,
                                         transactionAuthor: "getVaultKeysCount")

        let fetchRequest = CDVaultKey.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        return try await count(for: fetchRequest, withContext: taskContext)
    }

    func getItemKeysCount(forShareId shareId: String) async throws -> Int {
        let taskContext = newTaskContext(type: .fetch,
                                         transactionAuthor: "getItemKeysCount")

        let fetchRequest = CDItemKey.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        return try await count(for: fetchRequest, withContext: taskContext)
    }

    func fetchItemKeys(forShareId shareId: String,
                       page: Int,
                       pageSize: Int) async throws -> [ItemKey] {
        let taskContext = newTaskContext(type: .fetch,
                                         transactionAuthor: "fetchItemKeys")

        let fetchRequest = CDItemKey.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        fetchRequest.fetchLimit = pageSize
        fetchRequest.fetchOffset = page * pageSize
        let cdItemKeys = try await fetch(request: fetchRequest,
                                         withContext: taskContext)
        return try cdItemKeys.map { try $0.toItemKey() }
    }
}
