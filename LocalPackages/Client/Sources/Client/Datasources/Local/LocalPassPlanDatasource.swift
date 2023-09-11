//
// LocalPassPlanDatasource.swift
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

import Foundation

public protocol LocalPassPlanDatasourceProtocol: LocalDatasourceProtocol {
    func getPassPlan(userId: String) async throws -> PassPlan?
    func upsert(passPlan: PassPlan, userId: String) async throws
}

public extension LocalPassPlanDatasourceProtocol {
    func getPassPlan(userId: String) async throws -> PassPlan? {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = PassPlanEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.compactMap { $0.toPassPlan() }.first
    }

    func upsert(passPlan: PassPlan, userId: String) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
            newBatchInsertRequest(entity: PassPlanEntity.entity(context: taskContext),
                                  sourceItems: [passPlan]) { managedObject, passPlan in
                (managedObject as? PassPlanEntity)?.hydrate(from: passPlan, userId: userId)
            }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }
}

public final class LocalPassPlanDatasource: LocalDatasource, LocalPassPlanDatasourceProtocol {}
