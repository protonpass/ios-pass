//
// LocalDataMigrationDatasource.swift
// Proton Pass - Created on 20/06/2024.
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

import CoreData
import Entities
import Foundation

public protocol LocalDataMigrationDatasourceProtocol: Sendable {
    func getMigrations() async throws -> MigrationStatus?
    func upsert(migrations: MigrationStatus) async throws
}

public final class LocalDataMigrationDatasource: LocalDatasource, LocalDataMigrationDatasourceProtocol {}

public extension LocalDataMigrationDatasource {
    func getMigrations() async throws -> MigrationStatus? {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = MigrationStatusEntity.fetchRequest()
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return entities.compactMap { MigrationStatus(completedMigrations: Int($0.completedMigrations)) }.first
    }

    func upsert(migrations: MigrationStatus) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
            newBatchInsertRequest(entity: MigrationStatusEntity.entity(context: taskContext),
                                  sourceItems: [migrations]) { managedObject, migration in
                (managedObject as? MigrationStatusEntity)?
                    .hydrate(completedMigrations: migration.completedMigrations)
            }
        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }
}
