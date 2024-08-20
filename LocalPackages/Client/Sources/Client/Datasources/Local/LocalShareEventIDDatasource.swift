//
// LocalShareEventIDDatasource.swift
// Proton Pass - Created on 27/10/2022.
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

public protocol LocalShareEventIDDatasourceProtocol: Sendable {
    /// Get last event ID of a share
    func getLastEventId(userId: String, shareId: String) async throws -> String?

    /// Upsert last event ID of a share
    func upsertLastEventId(userId: String, shareId: String, lastEventId: String) async throws

    // periphery:ignore
    /// Remove everything
    func removeAllEntries(userId: String) async throws
}

public final class LocalShareEventIDDatasource: LocalDatasource, LocalShareEventIDDatasourceProtocol {}

public extension LocalShareEventIDDatasource {
    func getLastEventId(userId: String, shareId: String) async throws -> String? {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = ShareEventIDEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "userID = %@", userId),
            .init(format: "shareID = %@", shareId)
        ])
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        assert(entities.count <= 1, "Maximum 1 ShareEventIDEntity per shareID")
        return entities.first?.lastEventID
    }

    func upsertLastEventId(userId: String, shareId: String, lastEventId: String) async throws {
        try await upsertElements(items: [lastEventId],
                                 fetchPredicate: NSPredicate(format: "userID == %@ AND shareID == %@", userId,
                                                             shareId),
                                 itemComparisonKey: { _ in
                                     ShareEventIDKeyComparison(userId: userId, shareId: shareId)
                                 },
                                 entityComparisonKey: { entity in
                                     ShareEventIDKeyComparison(userId: entity.userID, shareId: entity.shareID)
                                 },
                                 updateEntity: { (entity: ShareEventIDEntity, _: String) in
                                     entity.hydrate(userId: userId,
                                                    shareId: shareId,
                                                    lastEventId: lastEventId)
                                 },
                                 insertItems: { [weak self] lastEventId in
                                     guard let self else { return }
                                     try await insert(userId: userId,
                                                      shareId: shareId,
                                                      lastEventId: lastEventId)
                                 })
    }

    func removeAllEntries(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ShareEventIDEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}

private extension LocalShareEventIDDatasource {
    struct ShareEventIDKeyComparison: Hashable {
        let userId: String
        let shareId: String
    }

    func insert(userId: String, shareId: String, lastEventId: [String]) async throws {
        let taskContext = newTaskContext(type: .insert)
        let batchInsertRequest =
            newBatchInsertRequest(entity: ShareEventIDEntity.entity(context: taskContext),
                                  sourceItems: lastEventId) { managedObject, lastEventId in
                (managedObject as? ShareEventIDEntity)?.hydrate(userId: userId,
                                                                shareId: shareId,
                                                                lastEventId: lastEventId)
            }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }
}
