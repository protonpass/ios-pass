//
// LocalUserEventIdDatasource.swift
// Proton Pass - Created on 16/05/2025.
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
//

import CoreData
import Foundation

public protocol LocalUserEventIdDatasourceProtocol: Sendable {
    func getLastEventId(userId: String) async throws -> String?
    func upsertLastEventId(userId: String, lastEventId: String) async throws
    func removeLastEventId(userId: String) async throws
}

public final class LocalUserEventIdDatasource:
    LocalDatasource, LocalUserEventIdDatasourceProtocol, @unchecked Sendable {}

public extension LocalUserEventIdDatasource {
    func getLastEventId(userId: String) async throws -> String? {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = UserEventIDEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        assert(entities.count <= 1, "Maximum 1 lastEventID per userID")
        return entities.first?.lastEventID
    }

    func upsertLastEventId(userId: String, lastEventId: String) async throws {
        try await upsert([lastEventId],
                         entityType: UserEventIDEntity.self,
                         fetchPredicate: NSPredicate(format: "userID == %@", userId),
                         isEqual: { _, entity in
                             entity.userID == userId
                         },
                         hydrate: { item, entity in
                             entity.hydrate(userId: userId, lastEventId: item)
                         })
    }

    func removeLastEventId(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "UserEventIDEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
