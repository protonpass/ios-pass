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
    /// All persisted compromised-password checks for a user.
    func getChecks(userId: String) async throws -> [CompromisedPasswordCheck]

    /// Persisted checks for a user, restricted to the given item ids.
    func getChecks(userId: String, itemIds: [String]) async throws -> [CompromisedPasswordCheck]

    /// Insert or update the given checks for a user.
    func upsert(_ checks: [CompromisedPasswordCheck], userId: String) async throws

    /// Remove checks for items no longer present (e.g. deleted items).
    func remove(userId: String, staleItemIds: [String]) async throws

    /// Remove all checks (and the cached corpus freshness marker) for a user.
    func removeAll(userId: String) async throws

    /// Cached UNIX epoch seconds of the corpus's last change at the previous successful scan.
    func getLastChange(userId: String) -> Int?

    /// Persist (or clear with `nil`) the corpus freshness marker.
    func setLastChange(_ value: Int?, userId: String)
}

public final class LocalCompromisedPasswordDatasource: LocalDatasource,
    LocalCompromisedPasswordDatasourceProtocol, @unchecked Sendable {
    private let userDefaults: UserDefaults

    public init(databaseService: any DatabaseServiceProtocol,
                userDefaults: UserDefaults = kSharedUserDefaults) {
        self.userDefaults = userDefaults
        super.init(databaseService: databaseService)
    }
}

public extension LocalCompromisedPasswordDatasource {
    func getChecks(userId: String) async throws -> [CompromisedPasswordCheck] {
        let context = newTaskContext(type: .fetch)
        let request = CompromisedPasswordCheckEntity.fetchRequest()
        request.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: request, context: context)
        return entities.map { $0.toCompromisedPasswordCheck() }
    }

    func getChecks(userId: String, itemIds: [String]) async throws -> [CompromisedPasswordCheck] {
        guard !itemIds.isEmpty else {
            return []
        }
        let context = newTaskContext(type: .fetch)
        let request = CompromisedPasswordCheckEntity.fetchRequest()
        request.predicate = .init(format: "userID == %@ AND itemID IN %@", userId, itemIds)
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

    func remove(userId: String, staleItemIds: [String]) async throws {
        guard !staleItemIds.isEmpty else {
            return
        }
        let context = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName:
            "CompromisedPasswordCheckEntity")
        fetchRequest.predicate = .init(format: "userID == %@ AND itemID IN %@", userId, staleItemIds)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest), context: context)
    }

    func removeAll(userId: String) async throws {
        let context = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName:
            "CompromisedPasswordCheckEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest), context: context)
        setLastChange(nil, userId: userId)
    }

    func getLastChange(userId: String) -> Int? {
        let key = lastChangeKey(userId: userId)
        guard userDefaults.object(forKey: key) != nil else {
            return nil
        }
        return userDefaults.integer(forKey: key)
    }

    func setLastChange(_ value: Int?, userId: String) {
        let key = lastChangeKey(userId: userId)
        if let value {
            userDefaults.set(value, forKey: key)
        } else {
            userDefaults.removeObject(forKey: key)
        }
    }
}

private extension LocalCompromisedPasswordDatasource {
    func lastChangeKey(userId: String) -> String {
        "compromisedPasswordsLastChange.\(userId)"
    }
}
