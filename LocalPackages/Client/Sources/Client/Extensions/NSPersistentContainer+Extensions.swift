//
// NSPersistentContainer+Extensions.swift
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

import CoreData

public extension NSPersistentContainer {
    static func model(for name: String) -> NSManagedObjectModel {
        guard let url = Bundle.module.url(forResource: name, withExtension: "momd")
        else { fatalError("Could not get URL for model: \(name)") }

        guard let model = NSManagedObjectModel(contentsOf: url)
        else { fatalError("Could not get model for: \(url)") }

        return model
    }
}
