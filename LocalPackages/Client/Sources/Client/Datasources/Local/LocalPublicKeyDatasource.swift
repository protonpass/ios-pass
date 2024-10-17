//
// LocalPublicKeyDatasource.swift
// Proton Pass - Created on 17/08/2022.
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

import Entities
import Foundation

public protocol LocalPublicKeyDatasourceProtocol: Sendable {
    func getPublicKeys(email: String) async throws -> [PublicKey]
    func insertPublicKeys(_ publicKeys: [PublicKey], email: String) async throws
}

public final class LocalPublicKeyDatasource: LocalDatasource, LocalPublicKeyDatasourceProtocol,
    @unchecked Sendable {}

public extension LocalPublicKeyDatasource {
    func getPublicKeys(email: String) async throws -> [PublicKey] {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = PublicKeyEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "email = %@", email)
        let publicKeyEntities = try await execute(fetchRequest: fetchRequest,
                                                  context: taskContext)
        return try publicKeyEntities.map { try $0.toPublicKey() }
    }

    func insertPublicKeys(_ publicKeys: [PublicKey], email: String) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
            newBatchInsertRequest(entity: PublicKeyEntity.entity(context: taskContext),
                                  sourceItems: publicKeys) { managedObject, publicKey in
                (managedObject as? PublicKeyEntity)?.hydrate(from: publicKey, email: email)
            }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }
}
