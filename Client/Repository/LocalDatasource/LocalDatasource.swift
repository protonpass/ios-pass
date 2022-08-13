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

import CoreData

private let kPassContainerName = "Pass"

public enum LocalDatasourceError: Error, CustomDebugStringConvertible {
    case batchInsertError(NSBatchInsertRequest)

    public var debugDescription: String {
        switch self {
        case .batchInsertError(let request):
            return "Failed to batch insert for entity \(request.entityName)"
        }
    }
}

public enum PassPersistentContainerBuilder {
    public static func build(inMemory: Bool) -> NSPersistentContainer {
        let container = NSPersistentContainer(name: kPassContainerName)
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
        return container
    }
}

public class LocalDatasourceV2 {
    let container: NSPersistentContainer

    public init(container: NSPersistentContainer) {
        guard container.name == kPassContainerName else {
            fatalError("Unsupported container name \(container.name)")
        }
        self.container = container
    }

    private enum TaskContextType: String {
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
extension LocalDatasourceV2 {
    private func execute(batchInsertRequest request: NSBatchInsertRequest,
                         context: NSManagedObjectContext) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in
            context.performAndWait {
                do {
                    let fetchResult = try context.execute(request)
                    if let result = fetchResult as? NSBatchInsertResult,
                       let success = result.result as? Bool, success {
                        continuation.resume()
                    } else {
                        continuation.resume(throwing: LocalDatasourceError.batchInsertError(request))
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func execute<T>(fetchRequest request: NSFetchRequest<T>,
                            context: NSManagedObjectContext) async throws -> [T] {
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

    private func count<T>(fetchRequest request: NSFetchRequest<T>,
                          context: NSManagedObjectContext) async throws -> Int {
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
