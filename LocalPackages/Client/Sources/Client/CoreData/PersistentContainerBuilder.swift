//
// PersistentContainerBuilder.swift
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

import Core
import CoreData

public extension NSPersistentContainer {
    enum Builder {
        public static func build(name: String, inMemory: Bool) -> NSPersistentContainer {
            let model = NSPersistentContainer.model(for: name)
            let container = NSPersistentContainer(name: name, managedObjectModel: model)

            let url: URL
            if inMemory {
                url = URL(fileURLWithPath: "/dev/null")
            } else {
                url = URL.storeURL(for: Constants.appGroup, databaseName: name)
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

    static func model(for name: String) -> NSManagedObjectModel {
        guard let url = Bundle.module.url(forResource: name, withExtension: "momd")
        else { fatalError("Could not get URL for model: \(name)") }

        guard let model = NSManagedObjectModel(contentsOf: url)
        else { fatalError("Could not get model for: \(url)") }

        return model
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
