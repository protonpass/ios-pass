//
// LocalInviteDatasource.swift
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

public protocol LocalInviteDatasourceProtocol: Sendable {
    // MARK: - User invites

    func getUserInvites(userId: String) async throws -> [UserInvite]
    func upsertUserInvites(userId: String, invites: [UserInvite]) async throws
    // Remove specific invites (e.g after accepting or rejecting an invite)
    func removeUserInvites(userId: String, invites: [UserInvite]) async throws
    func removeAllUserInvites(userId: String) async throws

    // MARK: - Group invites

    func getGroupInvites(userId: String) async throws -> [GroupInvite]
    func upsertGroupInvites(userId: String, invites: [GroupInvite]) async throws
    func removeGroupInvites(userId: String, invites: [GroupInvite]) async throws
    func removeAllGroupInvites(userId: String) async throws

    // Remove invites related to a user (e.g after logging from an account)
    func removeAllInvites(userId: String) async throws
}

public extension LocalInviteDatasourceProtocol {
    func removeUserInvites(userId: String, invite: UserInvite) async throws {
        try await removeUserInvites(userId: userId, invites: [invite])
    }

    func removeGroupInvites(userId: String, invite: GroupInvite) async throws {
        try await removeGroupInvites(userId: userId, invites: [invite])
    }
}

public final class LocalInviteDatasource: LocalDatasource, LocalInviteDatasourceProtocol,
    @unchecked Sendable {}

// MARK: - User

public extension LocalInviteDatasource {
    func getUserInvites(userId: String) async throws -> [UserInvite] {
        try await getInvites(userId: userId, entity: UserInviteEntity.self, map: \.toUserInvite)
    }

    func upsertUserInvites(userId: String, invites: [UserInvite]) async throws {
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

    func removeUserInvites(userId: String, invites: [UserInvite]) async throws {
        try await removeInvites(userId: userId, invites: invites,
                                entity: UserInviteEntity.self,
                                tokenKeyPath: \.inviteToken)
    }

    func removeAllUserInvites(userId: String) async throws {
        try await removeAllInvites(userId: userId, entity: UserInviteEntity.self)
    }

    func removeAllInvites(userId: String) async throws {
        let deleteContext = newTaskContext(type: .delete)

        try await deleteEntities(["UserInviteEntity", "GroupInviteEntity"],
                                 userId: userId,
                                 context: deleteContext)
    }
}

// MARK: - Group

public extension LocalInviteDatasource {
    // Group
    func getGroupInvites(userId: String) async throws -> [GroupInvite] {
        try await getInvites(userId: userId, entity: GroupInviteEntity.self, map: \.toGroupInvite)
    }

    func upsertGroupInvites(userId: String, invites: [GroupInvite]) async throws {
        try await upsertWithRelationships(invites,
                                          entityType: GroupInviteEntity.self,
                                          fetchPredicate: NSPredicate(format: "userID = %@", userId),
                                          isEqual: { $0.inviteToken == $1.inviteToken },
                                          hydrate: { invite, entity, context in
                                              entity.hydrate(userID: userId, invite: invite, context: context)
                                          })
    }

    func removeGroupInvites(userId: String, invites: [GroupInvite]) async throws {
        try await removeInvites(userId: userId,
                                invites: invites,
                                entity: GroupInviteEntity.self,
                                tokenKeyPath: \.inviteToken)
    }

    func removeAllGroupInvites(userId: String) async throws {
        try await removeAllInvites(userId: userId, entity: GroupInviteEntity.self)
    }
}

// MARK: - Utils

private extension LocalInviteDatasource {
    func deleteEntities(_ entityNames: [String],
                        userId: String,
                        context: NSManagedObjectContext) async throws {
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            fetchRequest.predicate = NSPredicate(format: "userID == %@", userId)
            try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                              context: context)
        }
    }
}

// MARK: - Generic Helpers

private extension LocalInviteDatasource {
    func getInvites<T: Sendable, E>(userId: String,
                                    entity: E.Type,
                                    map: (E) -> T) async throws -> [T] where E: NSManagedObject {
        let fetchContext = newTaskContext(type: .fetch)
        let fetchRequest = NSFetchRequest<E>(entityName: String(describing: entity))
        fetchRequest.predicate = NSPredicate(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: fetchContext)
        return entities.map(map)
    }

    func removeInvites<T>(userId: String,
                          invites: [T],
                          entity: (some NSManagedObject).Type,
                          tokenKeyPath: KeyPath<T, String>) async throws {
        let deleteContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entity))
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "userID = %@", userId),
            NSPredicate(format: "inviteToken IN %@", invites.map { $0[keyPath: tokenKeyPath] })
        ])
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest), context: deleteContext)
    }

    func removeAllInvites(userId: String,
                          entity: (some NSManagedObject).Type) async throws {
        let deleteContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: String(describing: entity))
        fetchRequest.predicate = NSPredicate(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest), context: deleteContext)
    }
}
