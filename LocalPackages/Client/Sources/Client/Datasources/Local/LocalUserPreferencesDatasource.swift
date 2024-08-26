//
// LocalUserPreferencesDatasource.swift
// Proton Pass - Created on 29/03/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import CryptoKit
import Entities
import Foundation

// sourcery: AutoMockable
/// Store symmetrically encrypted `UserPreferences` in core data
public protocol LocalUserPreferencesDatasourceProtocol: Sendable {
    func getPreferences(for userId: String) async throws -> UserPreferences?
    func upsertPreferences(_ preferences: UserPreferences, for userId: String) async throws
    func removePreferences(for userId: String) async throws
    func removeAllPreferences() async throws
}

public final class LocalUserPreferencesDatasource: LocalDatasource, LocalUserPreferencesDatasourceProtocol {
    private let symmetricKeyProvider: any SymmetricKeyProvider

    public init(symmetricKeyProvider: any SymmetricKeyProvider,
                databaseService: any DatabaseServiceProtocol) {
        self.symmetricKeyProvider = symmetricKeyProvider
        super.init(databaseService: databaseService)
    }
}

public extension LocalUserPreferencesDatasource {
    func getPreferences(for userId: String) async throws -> UserPreferences? {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = UserPreferencesEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        assert(entities.count <= 1, "Can not have more than 1 preferences per userId")
        let key = try await symmetricKeyProvider.getSymmetricKey()
        return try entities.first?.toUserPreferences(key)
    }

    func upsertPreferences(_ preferences: UserPreferences, for userId: String) async throws {
        let key = try await symmetricKeyProvider.getSymmetricKey()
        try await upsert([preferences],
                         entityType: UserPreferencesEntity.self,
                         fetchPredicate: NSPredicate(format: "userID == %@", userId),
                         isEqual: { _, entity in
                             entity.userID == userId
                         },
                         hydrate: { item, entity in
                             try entity.hydrate(preferences: item, userId: userId, key: key)
                         })
    }

    func removePreferences(for userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "UserPreferencesEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func removeAllPreferences() async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "UserPreferencesEntity")
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
