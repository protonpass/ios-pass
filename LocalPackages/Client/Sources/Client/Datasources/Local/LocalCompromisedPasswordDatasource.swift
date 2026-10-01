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
    func getChecks(userId: String) async throws -> [CompromisedPasswordCheck]
    func upsert(_ checks: [CompromisedPasswordCheck], userId: String) async throws
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

    func upsert(_ checks: [CompromisedPasswordCheck], userId: String) async throws {
        guard !checks.isEmpty else {
            return
        }
        let context = newTaskContext(type: .insert)
        // The (userID, shareID, itemID) uniqueness constraint makes the batch insert overwrite
        // existing rows, so no fetch-and-match pass is needed
        let request = newBatchInsertRequest(entity: CompromisedPasswordCheckEntity.entity(context: context),
                                            sourceItems: checks) { object, check in
            (object as? CompromisedPasswordCheckEntity)?.hydrate(from: check, userId: userId)
        }
        try await execute(batchInsertRequest: request, context: context)
    }

    func remove(userId: String, staleItemIds: [any ItemIdentifiable]) async throws {
        guard !staleItemIds.isEmpty else {
            return
        }
        let staleIds = Set(staleItemIds.map(\.ids))
        let itemIds = staleItemIds.map(\.itemId)
        let context = newTaskContext(type: .delete)
        let objectIds = try await context.perform {
            let request = CompromisedPasswordCheckEntity.fetchRequest()
            // `itemID IN` alone over-matches when an item id exists in several shares, so the exact
            // (share, item) pair is checked on the fetched rows
            request.predicate = NSPredicate(format: "userID == %@ AND itemID IN %@", userId, itemIds)
            return try context.fetch(request)
                .filter { staleIds.contains(IDs(shareId: $0.shareID, itemId: $0.itemID)) }
                .map(\.objectID)
        }
        guard !objectIds.isEmpty else {
            return
        }
        try await execute(batchDeleteRequest: .init(objectIDs: objectIds), context: context)
    }

    func removeAll(userId: String) async throws {
        let context = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName:
            "CompromisedPasswordCheckEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest), context: context)
    }
}
