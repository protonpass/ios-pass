//
// LocalShareDatasource.swift
// Proton Pass - Created on 13/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public protocol LocalShareDatasourceProtocol {
    func getShare(userId: String, shareId: String) async throws -> Share?
    func getAllShares(userId: String) async throws -> [Share]
    func upsertShares(_ shares: [Share], userId: String) async throws
    func removeAllShares(userId: String) async throws
}

public final class LocalShareDatasource: BaseLocalDatasource {}

extension LocalShareDatasource: LocalShareDatasourceProtocol {
    public func getShare(userId: String, shareId: String) async throws -> Share? {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = ShareEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(
            orPredicateWithSubpredicates: [
                .init(format: "userID = %@", userId),
                .init(format: "shareID = %@", shareId)
            ])
        let shareEntities = try await execute(fetchRequest: fetchRequest,
                                              context: taskContext)
        return try shareEntities.map { try $0.toShare() }.first
    }

    public func getAllShares(userId: String) async throws -> [Share] {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = ShareEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let shareEntities = try await execute(fetchRequest: fetchRequest,
                                              context: taskContext)
        return try shareEntities.map { try $0.toShare() }
    }

    public func upsertShares(_ shares: [Share], userId: String) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
        newBatchInsertRequest(entity: ShareEntity.entity(context: taskContext),
                              sourceItems: shares) { managedObject, share in
            (managedObject as? ShareEntity)?.hydrate(from: share, userId: userId)
        }

        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    public func removeAllShares(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ShareEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
