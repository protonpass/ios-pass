//
// LocalSpotlightVaultDatasource.swift
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

public protocol LocalSpotlightVaultDatasourceProtocol: Sendable {
    func getIds(for userId: String) async throws -> [ShareID]
    func setIds(for userId: String, ids: [ShareID]) async throws
    func removeAll(for userId: String) async throws
}

public final class LocalSpotlightVaultDatasource: LocalDatasource, LocalSpotlightVaultDatasourceProtocol,
    @unchecked Sendable {}

public extension LocalSpotlightVaultDatasource {
    func getIds(for userId: String) async throws -> [ShareID] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = SpotlightVaultEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.map(\.shareID)
    }

    func setIds(for userId: String, ids: [ShareID]) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
            newBatchInsertRequest(entity: SpotlightVaultEntity.entity(context: taskContext),
                                  sourceItems: ids) { managedObject, id in
                (managedObject as? SpotlightVaultEntity)?.userID = userId
                (managedObject as? SpotlightVaultEntity)?.shareID = id
            }

        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    func removeAll(for userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "SpotlightVaultEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
