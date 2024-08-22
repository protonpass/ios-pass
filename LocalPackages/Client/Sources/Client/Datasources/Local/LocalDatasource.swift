//
// LocalDatasource.swift
// Proton Pass - Created on 13/08/2022.
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

@preconcurrency import CoreData

let kProtonPassContainerName = "ProtonPass"

public enum TaskContextType: String {
    case insert = "insertContext"
    case delete = "deleteContext"
    case fetch = "fetchContext"
}

enum LocalDatasourceError: Error, CustomDebugStringConvertible {
    case batchInsertError(NSBatchInsertRequest)
    case batchDeleteError(NSBatchDeleteRequest)
    case databaseOperationsOnMainThread
    case corruptedShareKeys(shareId: String, itemKeyCount: Int, vaultKeyCount: Int)

    public var debugDescription: String {
        switch self {
        case let .batchInsertError(request):
            return "Failed to batch insert entity \(request.entityName)"
        case let .batchDeleteError(request):
            let entityName = request.fetchRequest.entityName ?? ""
            return "Failed to batch delete entity \(entityName)"
        case .databaseOperationsOnMainThread:
            return "Cannot do database operations on main thread"
        case let .corruptedShareKeys(shareId, itemKeyCount, vaultKeyCount):
            return """
            "Corrupted share keys for share \(shareId).
            Item key count (\(itemKeyCount)) not equal to vault key count (\(vaultKeyCount)
            """
        }
    }
}

public class LocalDatasource: @unchecked Sendable {
    private let databaseService: any DatabaseServiceProtocol
    private var container: NSPersistentContainer {
        databaseService.getContainer()
    }

    public init(databaseService: any DatabaseServiceProtocol) {
        guard databaseService.getContainer().name == kProtonPassContainerName else {
            fatalError("Unsupported container name \"\(databaseService.getContainer().name)\"")
        }
        self.databaseService = databaseService
    }
}

public extension LocalDatasource {
    /// Creates and configures a private queue context.
    func newTaskContext(type: TaskContextType,
                        transactionAuthor: String = #function) -> NSManagedObjectContext {
        let taskContext = container.newBackgroundContext()
        taskContext.name = type.rawValue
        taskContext.transactionAuthor = transactionAuthor
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Set unused undoManager to nil for macOS (it is nil by default on iOS)
        // to reduce resource requirements.
        taskContext.undoManager = nil
        return taskContext
    }

    func newBatchInsertRequest<T>(entity: NSEntityDescription,
                                  sourceItems: [T],
                                  hydrateBlock: @escaping (NSManagedObject, T) -> Void)
        -> NSBatchInsertRequest {
        var index = 0
        let request = NSBatchInsertRequest(entity: entity,
                                           managedObjectHandler: { object in
                                               guard index < sourceItems.count else { return true }
                                               let item = sourceItems[index]
                                               hydrateBlock(object, item)
                                               index += 1
                                               return false
                                           })
        return request
    }

    func upsert<Item, Entity>(_ items: [Item],
                              entityType: Entity.Type,
                              fetchPredicate: NSPredicate,
                              isEqual: @escaping (Item, Entity) -> Bool,
                              hydrate: @escaping (Item, Entity) throws -> Void) async throws
        where Entity: NSManagedObject {
        guard !items.isEmpty else {
            return
        }

        let context = newTaskContext(type: .insert)

        // Fetch existing entities
        let fetchRequest = NSFetchRequest<Entity>(entityName: String(describing: Entity.self))
        fetchRequest.predicate = fetchPredicate

        let existingEntities = try await context.perform {
            try context.fetch(fetchRequest)
        }

        // Closure to insert new items
        let insert: ([Item]) async throws -> Void = { [weak self] itemsToInsert in
            guard let self else { return }
            let entity = entityType.entity(context: context)
            var hydrationError: (any Error)?
            let request = newBatchInsertRequest(entity: entity,
                                                sourceItems: itemsToInsert) { object, item in
                if let entityObject = object as? Entity {
                    do {
                        try hydrate(item, entityObject)
                    } catch {
                        hydrationError = error
                    }
                } else {
                    assertionFailure("Failed to parse entity as \(entity.self)")
                }
            }
            if let hydrationError {
                throw hydrationError
            }
            try await execute(batchInsertRequest: request, context: context)
        }

        if existingEntities.isEmpty {
            // Nothing exist yet => insert everything
            try await insert(items)
        } else {
            // Something exists => insert if not exist and update if exist
            var itemsToInsert = [Item]()
            for item in items {
                if let entityToUpdate = existingEntities.first(where: { isEqual(item, $0) }) {
                    try hydrate(item, entityToUpdate)
                } else {
                    itemsToInsert.append(item)
                }
            }

            try await context.perform {
                if context.hasChanges {
                    try context.save()
                }
            }

            if !itemsToInsert.isEmpty {
                try await insert(itemsToInsert)
            }
        }
    }
}

// MARK: - Covenience core data methods

extension LocalDatasource {
    func execute(batchInsertRequest request: NSBatchInsertRequest,
                 context: NSManagedObjectContext) async throws {
        try await context.perform {
            guard context.hasPersistentStore else { return }
            #if DEBUG
            if Thread.isMainThread {
                throw LocalDatasourceError.databaseOperationsOnMainThread
            }
            #endif
            let fetchResult = try context.execute(request)
            if let result = fetchResult as? NSBatchInsertResult,
               let success = result.result as? Bool, success {
                return
            } else {
                throw LocalDatasourceError.batchInsertError(request)
            }
        }
    }

    func execute(batchDeleteRequest request: NSBatchDeleteRequest,
                 context: NSManagedObjectContext) async throws {
        try await context.perform {
            guard context.hasPersistentStore else { return }
            #if DEBUG
            if Thread.isMainThread {
                throw LocalDatasourceError.databaseOperationsOnMainThread
            }
            #endif
            request.resultType = .resultTypeStatusOnly
            let deleteResult = try context.execute(request)
            if let result = deleteResult as? NSBatchDeleteResult,
               let success = result.result as? Bool, success {
                return
            } else {
                throw LocalDatasourceError.batchDeleteError(request)
            }
        }
    }

    func execute<T>(fetchRequest request: NSFetchRequest<T>,
                    context: NSManagedObjectContext) async throws -> [T] {
        try await context.perform {
            guard context.hasPersistentStore else { return [] }
            #if DEBUG
            if Thread.isMainThread {
                throw LocalDatasourceError.databaseOperationsOnMainThread
            }
            #endif
            return try context.fetch(request)
        }
    }

    func count(fetchRequest request: NSFetchRequest<some Any>,
               context: NSManagedObjectContext) async throws -> Int {
        try await context.perform {
            guard context.hasPersistentStore else { return 0 }
            #if DEBUG
            if Thread.isMainThread {
                throw LocalDatasourceError.databaseOperationsOnMainThread
            }
            #endif
            return try context.count(for: request)
        }
    }
}

extension NSManagedObject {
    /*
     Such helper function is due to a very strange 🐛 that makes
     unit tests failed out of the blue because `CoreDataEntityName.entity()`
     failed to return a non-null NSEntityDescription.
     `CoreDataEntityName.entity()` used to work for a while until
     it stops working on some machines. Not a reproducible 🐛
     */
    class func entity(context: NSManagedObjectContext) -> NSEntityDescription {
        // swiftlint:disable:next force_unwrapping
        .entity(forEntityName: "\(Self.self)", in: context)!
    }
}

extension NSManagedObjectContext {
    var hasPersistentStore: Bool {
        persistentStoreCoordinator?.persistentStores.isEmpty == false
    }
}
