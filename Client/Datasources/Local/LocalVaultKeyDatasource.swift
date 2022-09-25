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

public protocol LocalVaultKeyDatasourceProtocol: LocalDatasourceProtocol {
    /// Get vault keys of a share
    func getVaultKeys(shareId: String) async throws -> [VaultKey]

    /// Insert or update if exist vault keys
    func upsertVaultKeys(_ keys: [VaultKey], shareId: String) async throws

    /// Remove all item keys of a share
    func removeAllVaultKeys(shareId: String) async throws
}

public extension LocalVaultKeyDatasourceProtocol {
    func getVaultKeys(shareId: String) async throws -> [VaultKey] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = VaultKeyEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try entities.map { try $0.toVaultKey() }
    }

    func upsertVaultKeys(_ keys: [VaultKey], shareId: String) async throws {
        let taskContext = newTaskContext(type: .insert)
        let batchInsertRequest =
        newBatchInsertRequest(entity: VaultKeyEntity.entity(context: taskContext),
                              sourceItems: keys) { managedObject, vaultKey in
            (managedObject as? VaultKeyEntity)?.hydrate(from: vaultKey, shareId: shareId)
        }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    func removeAllVaultKeys(shareId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "VaultKeyEntity")
        fetchRequest.predicate = .init(format: "shareID = %@", shareId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}

public final class LocalVaultKeyDatasource: LocalDatasource, LocalVaultKeyDatasourceProtocol {}
