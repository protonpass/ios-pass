//
// LocalVaultKeyDatasource.swift
// Proton Pass - Created on 16/08/2022.
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

public protocol LocalVaultKeyDatasourceProtocol {
    func getVaultKey(shareId: String, rotationId: String) async throws -> VaultKey?
    func getVaultKeys(shareId: String, page: Int, pageSize: Int) async throws -> [VaultKey]
    func getVaultKeyCount(shareId: String) async throws -> Int
    func upsertVaultKeys(_ vaultKeys: [VaultKey], shareId: String) async throws
    func removeAllVaultKeys(shareId: String) async throws
}

public final class LocalVaultKeyDatasource: BaseLocalDatasource {}

extension LocalVaultKeyDatasource: LocalVaultKeyDatasourceProtocol {
    public func getVaultKey(shareId: String, rotationId: String) async throws -> VaultKey? {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = VaultKeyEntity.fetchRequest()
        fetchRequest.predicate = NSCompoundPredicate(
            andPredicateWithSubpredicates: [
                .init(format: "shareID = %@", shareId),
                .init(format: "rotationID = %@", rotationId)
            ])
        let vaultKeyEntities = try await execute(fetchRequest: fetchRequest,
                                                 context: taskContext)
        return try vaultKeyEntities.map { try $0.toVaultKey() }.first
    }

    public func getVaultKeys(shareId: String,
                             page: Int,
                             pageSize: Int) async throws -> [VaultKey] {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = vaultKeyEntityFetchRequest(shareId: shareId)
        fetchRequest.fetchLimit = pageSize
        fetchRequest.fetchOffset = page * pageSize
        let vaultKeyEntities = try await execute(fetchRequest: fetchRequest,
                                                 context: taskContext)
        return try vaultKeyEntities.map { try $0.toVaultKey() }
    }

    public func getVaultKeyCount(shareId: String) async throws -> Int {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = vaultKeyEntityFetchRequest(shareId: shareId)
        return try await count(fetchRequest: fetchRequest, context: taskContext)
    }

    public func upsertVaultKeys(_ vaultKeys: [VaultKey], shareId: String) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
        newBatchInsertRequest(entity: VaultKeyEntity.entity(context: taskContext),
                              sourceItems: vaultKeys) { managedObject, vaultKey in
            (managedObject as? VaultKeyEntity)?.hydrate(from: vaultKey, shareId: shareId)
        }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    public func removeAllVaultKeys(shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VaultKeyEntity")
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    private func vaultKeyEntityFetchRequest(shareId: String) -> NSFetchRequest<VaultKeyEntity> {
        let fetchRequest = VaultKeyEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        return fetchRequest
    }
}
