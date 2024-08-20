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

public protocol LocalShareDatasourceProtocol: Sendable {
    func getShare(userId: String, shareId: String) async throws -> SymmetricallyEncryptedShare?
    func getAllShares(userId: String) async throws -> [SymmetricallyEncryptedShare]
    func upsertShares(_ shares: [SymmetricallyEncryptedShare], userId: String) async throws
    func removeShare(shareId: String, userId: String) async throws
    func removeAllShares(userId: String) async throws
}

public final class LocalShareDatasource: LocalDatasource, LocalShareDatasourceProtocol {}

public extension LocalShareDatasource {
    func getShare(userId: String, shareId: String) async throws -> SymmetricallyEncryptedShare? {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = ShareEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "userID = %@", userId),
            .init(format: "shareID = %@", shareId)
        ])
        let shareEntities = try await execute(fetchRequest: fetchRequest,
                                              context: taskContext)
        return shareEntities.map { $0.toSymmetricallyEncryptedShare() }.first
    }

    func getAllShares(userId: String) async throws -> [SymmetricallyEncryptedShare] {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = ShareEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        fetchRequest.sortDescriptors = [.init(key: "createTime", ascending: false)]
        let shareEntities = try await execute(fetchRequest: fetchRequest,
                                              context: taskContext)
        return shareEntities.map { $0.toSymmetricallyEncryptedShare() }
    }

    func upsertShares(_ shares: [SymmetricallyEncryptedShare], userId: String) async throws {
        try await upsertElements(items: shares,
                                 fetchPredicate: NSPredicate(format: "shareID in %@", shares.map(\.share.shareID)),
                                 itemComparisonKey: { share in
                                     ShareKeyComparison(shareId: share.share.shareID)
                                 },
                                 entityComparisonKey: { entity in
                                     ShareKeyComparison(shareId: entity.shareID)
                                 },
                                 updateEntity: { (entity: ShareEntity, item: SymmetricallyEncryptedShare) in
                                     entity.hydrate(from: item, userId: userId)
                                 },
                                 insertItems: { [weak self] shares in
                                     guard let self else { return }
                                     try await insert(shares, userId: userId)
                                 })
    }

    func removeShare(shareId: String, userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ShareEntity")
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            .init(format: "userID = %@", userId),
            .init(format: "shareID = %@", shareId)
        ])
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func removeAllShares(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ShareEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}

private extension LocalShareDatasource {
    struct ShareKeyComparison: Hashable {
        let shareId: String
    }

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
    func insert(_ shares: [SymmetricallyEncryptedShare], userId: String) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
            newBatchInsertRequest(entity: ShareEntity.entity(context: taskContext),
                                  sourceItems: shares) { managedObject, share in
                (managedObject as? ShareEntity)?.hydrate(from: share, userId: userId)
            }

        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }
}
