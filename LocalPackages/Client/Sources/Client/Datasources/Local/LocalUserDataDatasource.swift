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
import Foundation
import ProtonCoreLogin

// sourcery: AutoMockable
public protocol LocalUserDataDatasourceProtocol: Sendable {
    /// Get all users sorted by `updateTime` from least to most recent (the last one is the latest)
    func getAll() async throws -> [UserData]
    func remove(userId: String) async throws
    func upsert(_ userData: UserData) async throws
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
    func getAll() async throws -> [UserData] {
        let context = newTaskContext(type: .fetch)
        let request = UserDataEntity.fetchRequest()
        request.sortDescriptors = [.init(key: "updateTime", ascending: true)]
        let entities = try await execute(fetchRequest: request, context: context)
        let key = try symmetricKeyProvider.getSymmetricKey()
        return try entities.map { try $0.toUserData(key) }
    }

    func remove(userId: String) async throws {
        let context = newTaskContext(type: .delete)
        let request = NSFetchRequest<any NSFetchRequestResult>(entityName: "UserDataEntity")
        request.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: request), context: context)
    }

    func upsert(_ userData: UserData) async throws {
        try await remove(userId: userData.user.ID)
        let context = newTaskContext(type: .insert)
        let key = try symmetricKeyProvider.getSymmetricKey()
        var hydrationError: (any Error)?
        let request = newBatchInsertRequest(entity: UserDataEntity.entity(context: context),
                                            sourceItems: [userData]) { object, userData in
            do {
                try (object as? UserDataEntity)?.hydrate(userData: userData, key: key)
            } catch {
                hydrationError = error
            }
        }
        if let hydrationError {
            throw hydrationError
        }
        try await execute(batchInsertRequest: request, context: context)
    }
}
