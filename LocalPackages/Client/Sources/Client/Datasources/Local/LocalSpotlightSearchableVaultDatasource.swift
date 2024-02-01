//
// LocalSpotlightSearchableVaultDatasource.swift
// Proton Pass - Created on 31/01/2024.
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

// swiftlint:disable:next type_name
public protocol LocalSpotlightSearchableVaultDatasourceProtocol: Sendable {
    func getIdsForSearchableVaults(for userId: String) async throws -> [ShareID]
    func setIdsForSearchableVaults(for userId: String, ids: [ShareID]) async throws
    func removeAllSearchableVaults(for userId: String) async throws
}

public final class LocalSpotlightSearchableVaultDatasource: LocalDatasource,
    LocalSpotlightSearchableVaultDatasourceProtocol {}

public extension LocalSpotlightSearchableVaultDatasource {
    func getIdsForSearchableVaults(for userId: String) async throws -> [ShareID] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = SpotlightSearchableVaultEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.map(\.shareID)
    }

    func setIdsForSearchableVaults(for userId: String, ids: [ShareID]) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
            newBatchInsertRequest(entity: SpotlightSearchableVaultEntity.entity(context: taskContext),
                                  sourceItems: ids) { managedObject, id in
                (managedObject as? SpotlightSearchableVaultEntity)?.userID = userId
                (managedObject as? SpotlightSearchableVaultEntity)?.shareID = id
            }

        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    func removeAllSearchableVaults(for userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "SpotlightSearchableVaultEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
