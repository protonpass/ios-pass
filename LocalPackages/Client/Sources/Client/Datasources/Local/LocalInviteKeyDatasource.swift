//
// LocalInviteKeyDatasource.swift
// Proton Pass - Created on 30/07/2025.
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

public protocol LocalInviteKeyDatasourceProtocol: Sendable {
    func getKeys(userId: String, inviteToken: String) async throws -> [InviteKey]
    func upsertKeys(userId: String, inviteToken: String, keys: [InviteKey]) async throws

    /// Remove keys related to an invite (e.g after accepting or rejecting the invite)
    func removeKeys(userId: String, inviteToken: String) async throws

    /// Remove keys related to a user (e.g after logging out from an account)
    func removeKeys(userId: String) async throws
}

public final class LocalInviteKeyDatasource: LocalDatasource, LocalInviteKeyDatasourceProtocol,
    @unchecked Sendable {}

public extension LocalInviteKeyDatasource {
    func getKeys(userId: String, inviteToken: String) async throws -> [InviteKey] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = InviteKeyEntity.fetchRequest()
        fetchRequest.predicate = predicate(userId: userId, inviteToken: inviteToken)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.map(\.toInviteKey)
    }

    func upsertKeys(userId: String, inviteToken: String, keys: [InviteKey]) async throws {
        try await upsert(keys,
                         entityType: InviteKeyEntity.self,
                         fetchPredicate: predicate(userId: userId, inviteToken: inviteToken),
                         isEqual: { key, entity in
                             entity.userID == userId &&
                                 entity.inviteToken == inviteToken &&
                                 entity.keyRotation == key.keyRotation
                         },
                         hydrate: { item, entity in
                             entity.hydrate(userID: userId, inviteToken: inviteToken, key: item)
                         })
    }

    func removeKeys(userId: String, inviteToken: String) async throws {
        let deleteContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "InviteKeyEntity")
        fetchRequest.predicate = predicate(userId: userId, inviteToken: inviteToken)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: deleteContext)
    }

    func removeKeys(userId: String) async throws {
        let deleteContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "InviteKeyEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: deleteContext)
    }
}

private extension LocalInviteKeyDatasource {
    func predicate(userId: String, inviteToken: String) -> NSPredicate {
        NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "userID = %@", userId),
            .init(format: "inviteToken = %@", inviteToken)
        ])
    }
}
