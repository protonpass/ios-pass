//
// LocalCompromisedPasswordDatasource.swift
// Proton Pass - Created on 18/06/2026.
// Copyright (c) 2026 Proton Technologies AG
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
//

import Core
import CoreData
import Entities
import Foundation

// sourcery: AutoMockable
public protocol LocalCompromisedPasswordDatasourceProtocol: Sendable {
    // periphery:ignore
    func getChecks(userId: String) async throws -> [CompromisedPasswordCheck]

    /// Persisted checks for a user, restricted to the given item ids.
    func getChecks(userId: String, items: [any ItemIdentifiable]) async throws -> [CompromisedPasswordCheck]
    func upsert(_ checks: [CompromisedPasswordCheck], userId: String) async throws
    // periphery:ignore
    func remove(userId: String, staleItemIds: [any ItemIdentifiable]) async throws
    func removeAll(userId: String) async throws
}

public final class LocalCompromisedPasswordDatasource: LocalDatasource,
    LocalCompromisedPasswordDatasourceProtocol, @unchecked Sendable {}

public extension LocalCompromisedPasswordDatasource {
    func getChecks(userId: String) async throws -> [CompromisedPasswordCheck] {
        let context = newTaskContext(type: .fetch)
        let request = CompromisedPasswordCheckEntity.fetchRequest()
        request.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: request, context: context)
        return entities.map { $0.toCompromisedPasswordCheck() }
    }

    func getChecks(userId: String, items: [any ItemIdentifiable]) async throws -> [CompromisedPasswordCheck] {
        guard !items.isEmpty else {
            return []
        }
        let context = newTaskContext(type: .fetch)
        let request = CompromisedPasswordCheckEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userID == %@ AND itemID IN %@ AND shareID IN %@",
                                        userId,
                                        items.map(\.itemId),
                                        items.map(\.shareId))

        let entities = try await execute(fetchRequest: request, context: context)
        return entities.map { $0.toCompromisedPasswordCheck() }
    }

    func upsert(_ checks: [CompromisedPasswordCheck], userId: String) async throws {
        try await upsert(checks,
                         entityType: CompromisedPasswordCheckEntity.self,
                         fetchPredicate: .init(format: "userID = %@", userId),
                         isEqual: { item, entity in
                             item.shareId == entity.shareID && item.itemId == entity.itemID
                         },
                         hydrate: { item, entity in
                             entity.hydrate(from: item, userId: userId)
                         })
    }

    func remove(userId: String, staleItemIds: [any ItemIdentifiable]) async throws {
        guard !staleItemIds.isEmpty else {
            return
        }
        let context = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName:
            "CompromisedPasswordCheckEntity")
        fetchRequest.predicate = NSPredicate(format: "userID == %@ AND itemID IN %@ AND shareID IN %@",
                                             userId,
                                             staleItemIds.map(\.itemId),
                                             staleItemIds.map(\.shareId))
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest), context: context)
    }

    func removeAll(userId: String) async throws {
        let context = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName:
            "CompromisedPasswordCheckEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest), context: context)
    }
}
