//
// LocalTelemetryEventDatasource.swift
// Proton Pass - Created on 19/04/2023.
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
import Entities

public protocol LocalTelemetryEventDatasourceProtocol: Sendable {
    /// - Parameters:
    ///   - count: the maximum number of events
    func getOldestEvents(count: Int, userId: String) async throws -> [TelemetryEvent]

    /// Get all events triggered by a user. For debugging purposes only.
    func getAllEvents(userId: String) async throws -> [TelemetryEvent]

    func insert(event: TelemetryEvent, userId: String) async throws

    func remove(events: [TelemetryEvent], userId: String) async throws

    func removeAllEvents(userId: String) async throws
}

public final class LocalTelemetryEventDatasource: LocalDatasource, LocalTelemetryEventDatasourceProtocol,
    @unchecked Sendable {}

public extension LocalTelemetryEventDatasource {
    func getOldestEvents(count: Int, userId: String) async throws -> [TelemetryEvent] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = TelemetryEventEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        fetchRequest.sortDescriptors = [.init(key: "time", ascending: true)]
        fetchRequest.fetchLimit = count
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try entities.map { try $0.toTelemetryEvent() }
    }

    func getAllEvents(userId: String) async throws -> [TelemetryEvent] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = TelemetryEventEntity.fetchRequest()
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        fetchRequest.sortDescriptors = [.init(key: "time", ascending: true)]
        let entities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return try entities.map { try $0.toTelemetryEvent() }
    }

    func insert(event: TelemetryEvent, userId: String) async throws {
        let taskContext = newTaskContext(type: .insert)

        let batchInsertRequest =
            newBatchInsertRequest(entity: TelemetryEventEntity.entity(context: taskContext),
                                  sourceItems: [event]) { managedObject, event in
                (managedObject as? TelemetryEventEntity)?.hydrate(from: event, userId: userId)
            }

        try await execute(batchInsertRequest: batchInsertRequest, context: taskContext)
    }

    func remove(events: [TelemetryEvent], userId: String) async throws {
        let context = newTaskContext(type: .delete)
        try await context.perform {
            for event in events {
                let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "TelemetryEventEntity")
                fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                    .init(format: "userID = %@", userId),
                    .init(format: "uuid = %@", event.uuid)
                ])
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try context.execute(batchDeleteRequest)
            }
            try context.save()
        }
    }

    func removeAllEvents(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "TelemetryEventEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
