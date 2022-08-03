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

    enum TaskContextName {
        static var `import` = "importContext"
        static var fetch = "fetchContext"
    }

    /// Creates and configures a private queue context.
    private func newTaskContext() -> NSManagedObjectContext {
        let taskContext = container.newBackgroundContext()
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
}

// MARK: - LocalDatasourceProtocol
extension LocalDatasource: LocalDatasourceProtocol {
    public func insertShares(_ shares: [Share],
                             withUserId userId: String) async throws {
        guard !shares.isEmpty else { return }

        let taskContext = newTaskContext()
        taskContext.name = TaskContextName.import
        taskContext.transactionAuthor = "importShares"

        var index = 0
        let batchInsertRequest = NSBatchInsertRequest(entity: CDShare.entity(),
                                                      managedObjectHandler: { object in
            guard index < shares.count else { return true }
            let share = shares[index]
            (object as? CDShare)?.copy(from: share, userId: userId)
            index += 1
            return false
        })

        try await execute(batchInsertRequest: batchInsertRequest, withContext: taskContext)
    }

    public func fetchShares(forUserId userId: String) async throws -> [Share] {
        guard !userId.isEmpty else { return [] }

        let taskContext = newTaskContext()
        taskContext.name = TaskContextName.fetch
        taskContext.transactionAuthor = "fetchShares"
        let fetchRequest = CDShare.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let cdShares = try await fetch(request: fetchRequest,
                                       withContext: taskContext)
        return try cdShares.map { try $0.toShare() }
    }
}
