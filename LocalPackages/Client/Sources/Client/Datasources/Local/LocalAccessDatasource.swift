//
// LocalAccessDatasource.swift
// Proton Pass - Created on 04/05/2023.
// Copyright (c) 2023 Proton Technologies AG
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

public protocol LocalAccessDatasourceProtocol {
    func getAccess(userId: String) async throws -> Access?
    func upsert(access: Access, userId: String) async throws
}

public final class LocalAccessDatasource: LocalDatasource, LocalAccessDatasourceProtocol {}

public extension LocalAccessDatasource {
    func getAccess(userId: String) async throws -> Access? {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = AccessEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.compactMap { $0.toAccess() }.first
    }

    func upsert(access: Access, userId: String) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
            newBatchInsertRequest(entity: AccessEntity.entity(context: taskContext),
                                  sourceItems: [access]) { managedObject, access in
                (managedObject as? AccessEntity)?.hydrate(from: access, userId: userId)
            }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }
}
