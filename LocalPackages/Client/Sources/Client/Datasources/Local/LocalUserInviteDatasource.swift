//
// LocalUserInviteDatasource.swift
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

public protocol LocalUserInviteDatasourceProtocol: Sendable {
    func getInvites(userId: String) async throws -> [UserInvite]
    func upsertInvites(userId: String, invites: [UserInvite]) async throws

    // Remove specific invites (e.g after accepting or rejecting an invite)
    func removeInvites(userId: String, invites: [UserInvite]) async throws

    // Remove invites related to a user (e.g after logging from an account)
    func removeInvites(userId: String) async throws
}

public extension LocalUserInviteDatasourceProtocol {
    func removeInvite(userId: String, invite: UserInvite) async throws {
        try await removeInvites(userId: userId, invites: [invite])
    }
}

public final class LocalUserInviteDatasource: LocalDatasource, LocalUserInviteDatasourceProtocol,
    @unchecked Sendable {}

public extension LocalUserInviteDatasource {
    func getInvites(userId: String) async throws -> [UserInvite] {
        let fetchContext = newTaskContext(type: .fetch)
        let fetchRequest = UserInviteEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: fetchContext)
        return entities.map(\.toUserInvite)
    }

    func upsertInvites(userId: String, invites: [UserInvite]) async throws {
        try await upsertWithRelationships(invites,
                                          entityType: UserInviteEntity.self,
                                          fetchPredicate: .init(format: "userID = %@", userId),
                                          isEqual: { invite, entity in
                                              entity.inviteToken == invite.inviteToken
                                          },
                                          hydrate: { invite, entity, context in
                                              entity.hydrate(userID: userId,
                                                             invite: invite,
                                                             context: context)
                                          })
    }

    func removeInvites(userId: String, invites: [UserInvite]) async throws {
        let deleteContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "UserInviteEntity")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "userID = %@", userId),
            .init(format: "inviteToken IN %@", invites.map(\.inviteToken))
        ])
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: deleteContext)
    }

    func removeInvites(userId: String) async throws {
        let deleteContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "UserInviteEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: deleteContext)
    }
}
