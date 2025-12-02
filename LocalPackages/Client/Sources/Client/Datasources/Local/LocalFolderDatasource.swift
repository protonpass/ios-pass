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
public protocol LocalFolderDatasourceProtocol: Sendable {}

public final class LocalFolderDatasource: LocalDatasource, LocalFolderDatasourceProtocol, @unchecked Sendable {}

public extension LocalFolderDatasource {
        func getAllFolders(userId: String) async throws -> [SymmetricallyEncryptedItem] {
            let taskContext = newTaskContext(type: .fetch)
            let fetchRequest = FolderEntity.fetchRequest()
            fetchRequest.predicate = .init(format: "userID = %@", userId)
            let itemEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
            return try itemEntities.map { try $0.toEncryptedFolder() }
        }
    
}
