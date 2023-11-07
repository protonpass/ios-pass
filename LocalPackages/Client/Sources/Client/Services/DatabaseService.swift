//
// DatabaseService.swift
// Proton Pass - Created on 07/11/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Foundation

public protocol DatabaseServiceProtocol {
    var container: NSPersistentContainer! { get }

    func resetContainer()
}

public final class DatabaseService: DatabaseServiceProtocol {
    public private(set) var container: NSPersistentContainer!
    private let logger: Logger

    public init(logManager: LogManagerProtocol) {
        logger = .init(manager: logManager)
        container = build(name: kProtonPassContainerName, inMemory: false)
    }

    public func resetContainer() {
        do {
            logger.info("Recreating Store")
            // Delete existing persistent stores
            let storeContainer = container.persistentStoreCoordinator
            for store in storeContainer.persistentStores {
                if let url = store.url {
                    try storeContainer.destroyPersistentStore(at: url, ofType: store.type)
                }
            }

            // Re-create persistent container
            container = build(name: kProtonPassContainerName, inMemory: false)
            logger.info("Nuked local data")
        } catch {
            logger.error(message: "Failed to reset database container", error: error)
        }
    }
}

// MARK: - Utils & Setup

private extension DatabaseServiceProtocol {
    func build(name: String, inMemory: Bool) -> NSPersistentContainer {
        let model = NSPersistentContainer.model(for: name)
        let container = NSPersistentContainer(name: name, managedObjectModel: model)

        let url = if inMemory {
            URL(fileURLWithPath: "/dev/null")
        } else {
            URL.storeURL(for: Constants.appGroup, databaseName: name)
        }
        /* add necessary support for migration */
        let description = NSPersistentStoreDescription(url: url)
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
        container.persistentStoreDescriptions = [description]
        /* add necessary support for migration */

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("Unresolved error \(error.localizedDescription)")
            }
        }
        return container
    }
}

private extension URL {
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer =
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
}

private extension NSPersistentContainer {
    static func model(for name: String) -> NSManagedObjectModel {
        guard let url = Bundle.module.url(forResource: name, withExtension: "momd")
        else { fatalError("Could not get URL for model: \(name)") }

        guard let model = NSManagedObjectModel(contentsOf: url)
        else { fatalError("Could not get model for: \(url)") }

        return model
    }
}
