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

    // swiftlint:disable:next function_parameter_count
    func upsertElements<ElementType, EntityType>(items: [ElementType],
                                                 fetchPredicate: NSPredicate,
                                                 itemComparisonKey: @escaping (ElementType) -> AnyHashable,
                                                 entityComparisonKey: @escaping (EntityType) -> AnyHashable,
                                                 updateEntity: @escaping (EntityType, ElementType) throws -> Void,
                                                 insertItems: @escaping ([ElementType]) async throws
                                                     -> Void) async throws where EntityType: NSManagedObject {
        let taskContext = newTaskContext(type: .insert)

        // Fetch existing entities based on the provided predicate
        let fetchRequest = NSFetchRequest<EntityType>(entityName: String(describing: EntityType.self))
        fetchRequest.predicate = fetchPredicate

        let existingEntities = try await taskContext.perform {
            try taskContext.fetch(fetchRequest)
        }

        // Use a Set for fast lookup
        let existingEntitiesDict = Dictionary(uniqueKeysWithValues: existingEntities
            .map { (entityComparisonKey($0),
                    $0) })

        if !existingEntitiesDict.isEmpty {
            var itemsToInsert: [ElementType] = []
            var itemsToUpdate: [(ElementType, EntityType)] = []

            // Separate items into those to insert or update
            for item in items {
                let key = itemComparisonKey(item)
                if let existingEntity = existingEntitiesDict[key] {
                    itemsToUpdate.append((item, existingEntity))
                } else {
                    itemsToInsert.append(item)
                }
            }

            // Perform batch update of existing entities
            if !itemsToUpdate.isEmpty {
                try await taskContext.perform {
                    for (item, entity) in itemsToUpdate {
                        try updateEntity(entity, item)
                    }
                    if taskContext.hasChanges {
                        try taskContext.save()
                    }
                }
            }

            // Perform batch insert for new items
            if !itemsToInsert.isEmpty {
                try await insertItems(itemsToInsert)
            }
        } else if !items.isEmpty {
            try await insertItems(items)
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
