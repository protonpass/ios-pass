//
// LocalAccessDatasource.swift
// Proton Pass - Created on 04/05/2023.
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
import Entities

// sourcery: AutoMockable
public protocol LocalAccessDatasourceProtocol: Sendable {
    func getAccess(userId: String) async throws -> UserAccess?
    func getAllAccesses() async throws -> [UserAccess]
    func upsert(access: UserAccess) async throws
    func removeAccess(userId: String) async throws

    func getPassUserInformations(userId: String) async throws -> PassUserInformations?
    func upsert(informations: PassUserInformations, userId: String) async throws
}

public final class LocalAccessDatasource: LocalDatasource, LocalAccessDatasourceProtocol, @unchecked Sendable {}

public extension LocalAccessDatasource {
    func getAccess(userId: String) async throws -> UserAccess? {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = AccessEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        assert(entities.count <= 1, "Should have maximum 1 access per user")
        return entities.compactMap { $0.toUserAccess() }.first
    }

    func getAllAccesses() async throws -> [UserAccess] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = AccessEntity.fetchRequest()
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.compactMap { $0.toUserAccess() }
    }

    func upsert(access: UserAccess) async throws {
        try await upsert([access],
                         entityType: AccessEntity.self,
                         fetchPredicate: NSPredicate(format: "userID == %@", access.userId),
                         isEqual: { item, entity in
                             item.userId == entity.userID
                         },
                         hydrate: { item, entity in
                             entity.hydrate(from: item)
                         })
    }

    func removeAccess(userId: String) async throws {
        let deleteContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "AccessEntity")
        fetchRequest.predicate = NSPredicate(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: deleteContext)
    }

    func getPassUserInformations(userId: String) async throws -> PassUserInformations? {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = PassUserInformationsEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        assert(entities.count <= 1, "Should have maximum 1 information per user")
        return entities.compactMap { $0.toPassUserInformations() }.first
    }

    func upsert(informations: PassUserInformations, userId: String) async throws {
        try await upsert([informations],
                         entityType: PassUserInformationsEntity.self,
                         fetchPredicate: NSPredicate(format: "userID == %@", userId),
                         isEqual: { _, entity in
                             userId == entity.userID
                         },
                         hydrate: { item, entity in
                             entity.hydrate(from: item, userId: userId)
                         })
    }
}
