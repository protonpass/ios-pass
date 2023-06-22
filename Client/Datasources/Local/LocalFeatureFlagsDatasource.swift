//
// LocalFeatureFlagsDatasource.swift
// Proton Pass - Created on 09/06/2023.
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

import CoreData

public protocol LocalFeatureFlagsDatasourceProtocol: LocalDatasourceProtocol {
    func getFeatureFlags(userId: String) async throws -> FeatureFlags?
    func upsertFlags(_ flags: FeatureFlags, userId: String) async throws
}

public extension LocalFeatureFlagsDatasourceProtocol {
    func getFeatureFlags(userId: String) async throws -> FeatureFlags? {
        let taskContext = newTaskContext(type: .fetch)

        let fetchRequest = FeatureFlagsEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        assert(entities.count <= 1, "Only max 1 feature flags object per user")
        return entities.compactMap { $0.toFeatureFlags() }.first
    }

    func upsertFlags(_ flags: FeatureFlags, userId: String) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
            newBatchInsertRequest(entity: FeatureFlagsEntity.entity(context: taskContext),
                                  sourceItems: [flags]) { managedObject, flags in
                (managedObject as? FeatureFlagsEntity)?.hydrate(from: flags, userId: userId)
            }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }
}

public final class LocalFeatureFlagsDatasource: LocalDatasource, LocalFeatureFlagsDatasourceProtocol {}
