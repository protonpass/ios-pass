//
// LocalNotificationTimeDatasource.swift
// Proton Pass - Created on 04/12/2024.
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

public protocol LocalNotificationTimeDatasourceProtocol: Sendable {
    func getNotificationTime(for userId: String) async throws -> TimeInterval?
    func upsertNotificationTime(_ timestamp: TimeInterval, for userId: String) async throws
    @_spi(QA)
    func removeNotificationTime(for userId: String) async throws
}

public final class LocalNotificationTimeDatasource:
    LocalDatasource, LocalNotificationTimeDatasourceProtocol, @unchecked Sendable {}

public extension LocalNotificationTimeDatasource {
    func getNotificationTime(for userId: String) async throws -> TimeInterval? {
        let context = newTaskContext(type: .fetch)
        let request = NotificationTimeEntity.fetchRequest()
        request.predicate = .init(format: "userID = %@", userId)
        let entities = try await execute(fetchRequest: request, context: context)
        assert(entities.count <= 1, "Should have at most 1 result")
        return entities.first?.time
    }

    func upsertNotificationTime(_ timestamp: TimeInterval, for userId: String) async throws {
        let context = newTaskContext(type: .insert)
        let request =
            newBatchInsertRequest(entity: NotificationTimeEntity.entity(context: context),
                                  sourceItems: [timestamp]) { managedObject, timestamp in
                (managedObject as? NotificationTimeEntity)?.hydrate(userId: userId,
                                                                    timestamp: timestamp)
            }

        try await execute(batchInsertRequest: request, context: context)
    }

    func removeNotificationTime(for userId: String) async throws {
        let context = newTaskContext(type: .delete)
        let request = NSFetchRequest<any NSFetchRequestResult>(entityName: "NotificationTimeEntity")
        request.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: request),
                          context: context)
    }
}
