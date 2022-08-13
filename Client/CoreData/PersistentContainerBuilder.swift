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

import CoreData

extension NSPersistentContainer {
    enum Builder {
        public static func build(name: String, inMemory: Bool) -> NSPersistentContainer {
            let container = NSPersistentContainer(name: name)
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
}
