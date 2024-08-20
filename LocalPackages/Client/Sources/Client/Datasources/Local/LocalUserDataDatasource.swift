//
// LocalUserDataDatasource.swift
// Proton Pass - Created on 14/05/2024.
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

// Remove later
// periphery:ignore:all
import CoreData
import CryptoKit
import Foundation
import ProtonCoreLogin

// sourcery: AutoMockable
public protocol LocalUserDataDatasourceProtocol: Sendable {
    /// Get all users sorted by `updateTime` from least to most recent (the last one is the latest)
    func getAll() async throws -> [UserProfile]
    func remove(userId: String) async throws
    func upsert(_ userData: UserData) async throws
    func updateNewActiveUser(userId: String) async throws
    func getActiveUser() async throws -> UserProfile?
    func removeAll() async throws
}

public final class LocalUserDataDatasource: LocalDatasource, LocalUserDataDatasourceProtocol {
    private let symmetricKeyProvider: any SymmetricKeyProvider

    public init(symmetricKeyProvider: any SymmetricKeyProvider,
                databaseService: any DatabaseServiceProtocol) {
        self.symmetricKeyProvider = symmetricKeyProvider
        super.init(databaseService: databaseService)
    }
}

public extension LocalUserDataDatasource {
    func getAll() async throws -> [UserProfile] {
        let context = newTaskContext(type: .fetch)
        let request = UserProfileEntity.fetchRequest()
        request.sortDescriptors = [.init(key: "updateTime", ascending: true)]
        let entities = try await execute(fetchRequest: request, context: context)
        let key = try await symmetricKeyProvider.getSymmetricKey()
        return try entities.map { try $0.toUserProfile(key) }
    }

    func remove(userId: String) async throws {
        let context = newTaskContext(type: .delete)
        let request = NSFetchRequest<any NSFetchRequestResult>(entityName: "UserProfileEntity")
        request.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: request), context: context)
    }

    func upsert(_ userData: UserData) async throws {
        let key = try await symmetricKeyProvider.getSymmetricKey()
        let userId = userData.user.ID
        try await upsertElements(items: [userData],
                                 fetchPredicate: NSPredicate(format: "userID == %@", userId),
                                 itemComparisonKey: { _ in
                    UserDataKeyComparison(userId: userId)
                                 },
                                 entityComparisonKey: { entity in
            UserDataKeyComparison(userId: entity.userID)
                                 },
                                 updateEntity: { (entity: UserProfileEntity, item: UserData) in
                                    try? entity.hydrate(userData: userData, key: key)
                                 },
                                 insertItems: { [weak self] userDatas in
                                     guard let self else { return }
                                     try await insert(userDatas, key: key)
                                 })
//        try await remove(userId: userData.user.ID)
//        let context = newTaskContext(type: .insert)
//        let key = try await symmetricKeyProvider.getSymmetricKey()
//        var hydrationError: (any Error)?
//        let request = newBatchInsertRequest(entity: UserProfileEntity.entity(context: context),
//                                            sourceItems: [userData]) { object, userData in
//            do {
//                try (object as? UserProfileEntity)?.hydrate(userData: userData, key: key)
//            } catch {
//                hydrationError = error
//            }
//        }
//        if let hydrationError {
//            throw hydrationError
//        }
//        try await execute(batchInsertRequest: request, context: context)
    }

    func getActiveUser() async throws -> UserProfile? {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = UserProfileEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "isActive = %d", true)
        let userDataEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        let key = try await symmetricKeyProvider.getSymmetricKey()
        assert(userDataEntities.count <= 1, "Should not have more than 1 active profile")
        return try userDataEntities.map { try $0.toUserProfile(key) }.first
    }

    func updateNewActiveUser(userId: String) async throws {
        let context = newTaskContext(type: .insert)
        try await context.perform {
            let request = UserProfileEntity.fetchRequest()
            let profiles = try context.fetch(request)

            if let activeProfile = profiles.first(where: { $0.isActive }) {
                activeProfile.isActive = false
            }

            // Find the new item by its ID and set it to active
            if let newActiveProfile = profiles.first(where: { $0.userID == userId }) {
                newActiveProfile.isActive = true
            }

            // Save the context to persist changes
            try context.save()
        }
    }

    func removeAll() async throws {
        let context = newTaskContext(type: .delete)
        let request = NSFetchRequest<any NSFetchRequestResult>(entityName: "UserProfileEntity")
        try await execute(batchDeleteRequest: .init(fetchRequest: request), context: context)
    }
}

private extension LocalUserDataDatasource {
    struct UserDataKeyComparison: Hashable {
        let userId: String
    }
    
    func insert(_ userData: [UserData], key: SymmetricKey) async throws {
        let context = newTaskContext(type: .insert)
//        let key = try await symmetricKeyProvider.getSymmetricKey()
        var hydrationError: (any Error)?
        let request = newBatchInsertRequest(entity: UserProfileEntity.entity(context: context),
                                            sourceItems: userData) { object, userData in
            do {
                try (object as? UserProfileEntity)?.hydrate(userData: userData, key: key)
            } catch {
                hydrationError = error
            }
        }
        if let hydrationError {
            throw hydrationError
        }
        try await execute(batchInsertRequest: request, context: context)
    }
//
//    func insertOrganization(_ organization: [Organization], userId: String) async throws {
//        let taskContext = newTaskContext(type: .insert)
//
//        let batchInsertRequest =
//            newBatchInsertRequest(entity: OrganizationEntity.entity(context: taskContext),
//                                  sourceItems: organization) { managedObject, organization in
//                (managedObject as? OrganizationEntity)?.hydrate(from: organization, userId: userId)
//            }
//
//        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
//    }
}
