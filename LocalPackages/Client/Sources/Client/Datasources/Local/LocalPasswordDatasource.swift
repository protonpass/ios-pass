//
// LocalPasswordDatasource.swift
// Proton Pass - Created on 09/04/2025.
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

public protocol LocalPasswordDatasourceProtocol: Sendable {
    func insertPassword(userId: String,
                        id: String,
                        symmetricallyEncryptedValue: String,
                        creationTime: TimeInterval) async throws
    func getAllPasswords(userId: String) async throws -> [GeneratedPassword]
    func getEncryptedPassword(id: String) async throws -> String?
    func deleteAllPasswords(userId: String) async throws
    func deletePassword(id: String) async throws
    func deletePasswords(cutOffTimestamp: Int) async throws
}

public final class LocalPasswordDatasource: LocalDatasource, LocalPasswordDatasourceProtocol,
    @unchecked Sendable {}

public extension LocalPasswordDatasource {
    func insertPassword(userId: String,
                        id: String,
                        symmetricallyEncryptedValue: String,
                        creationTime: TimeInterval) async throws {
        try await upsert([symmetricallyEncryptedValue],
                         entityType: PasswordEntity.self,
                         fetchPredicate: NSPredicate(format: "id == %@", id),
                         isEqual: { _, entity in
                             entity.id == id
                         },
                         hydrate: { _, entity in
                             entity.hydrate(userID: userId,
                                            id: id,
                                            creationTime: creationTime,
                                            symmetricallyEncryptedValue: symmetricallyEncryptedValue)
                         })
    }

    func getAllPasswords(userId: String) async throws -> [GeneratedPassword] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = PasswordEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        fetchRequest.sortDescriptors = [.init(key: "creationTime", ascending: false)]
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.map(\.toGeneratedPassword)
    }

    func getEncryptedPassword(id: String) async throws -> String? {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = PasswordEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "id = %@", id)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        assert(entities.count <= 1, "Should have at most 1 password for a given ID")
        return entities.first?.symmetricallyEncryptedValue
    }

    func deleteAllPasswords(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "PasswordEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func deletePassword(id: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "PasswordEntity")
        fetchRequest.predicate = .init(format: "id = %@", id)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func deletePasswords(cutOffTimestamp: Int) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "PasswordEntity")
        fetchRequest.predicate = .init(format: "creationTime <= %lld", cutOffTimestamp)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
