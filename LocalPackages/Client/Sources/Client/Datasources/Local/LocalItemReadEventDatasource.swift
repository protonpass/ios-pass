//
// LocalItemReadEventDatasource.swift
// Proton Pass - Created on 10/06/2024.
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
//

import CoreData
import Entities
import Foundation

public protocol LocalItemReadEventDatasourceProtocol: Sendable {
    /// Record new events
    func insertEvent(_ event: ItemReadEvent, userId: String) async throws

    /// Retrieve events by batch to send to the BE
    func getOldestEvents(count: Int, userId: String) async throws -> [ItemReadEvent]

    /// Retrieve all events for a user. For testing only.
    func getAllEvents(userId: String) async throws -> [ItemReadEvent]

    /// Remove events already sent to the BE
    func removeEvents(_ events: [ItemReadEvent]) async throws

    /// Remove all events related to a user
    func removeEvents(userId: String) async throws
}

public final class LocalItemReadEventDatasource: LocalDatasource, LocalItemReadEventDatasourceProtocol,
    @unchecked Sendable {}

public extension LocalItemReadEventDatasource {
    func insertEvent(_ event: ItemReadEvent,
                     userId: String) async throws {
        let context = newTaskContext(type: .insert)
        let request =
            newBatchInsertRequest(entity: ItemReadEventEntity.entity(context: context),
                                  sourceItems: [event]) { managedObject, event in
                (managedObject as? ItemReadEventEntity)?.hydrate(from: event, userId: userId)
            }

        try await execute(batchInsertRequest: request, context: context)
    }

    func getOldestEvents(count: Int, userId: String) async throws -> [ItemReadEvent] {
        let context = newTaskContext(type: .fetch)

        let request = ItemReadEventEntity.fetchRequest()
        request.predicate = .init(format: "userID = %@", userId)
        request.sortDescriptors = [.init(key: "time", ascending: true)]
        request.fetchLimit = count
        let entities = try await execute(fetchRequest: request,
                                         context: context)
        return entities.map { $0.toItemReadEvent() }
    }

    func getAllEvents(userId: String) async throws -> [ItemReadEvent] {
        let context = newTaskContext(type: .fetch)

        let request = ItemReadEventEntity.fetchRequest()
        request.predicate = .init(format: "userID = %@", userId)
        request.sortDescriptors = [.init(key: "time", ascending: true)]
        let entities = try await execute(fetchRequest: request,
                                         context: context)
        return entities.map { $0.toItemReadEvent() }
    }

    func removeEvents(_ events: [ItemReadEvent]) async throws {
        let context = newTaskContext(type: .delete)
        try await context.perform {
            for event in events {
                let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ItemReadEventEntity")
                fetchRequest.predicate = .init(format: "uuid = %@", event.uuid)
                let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try context.execute(batchDeleteRequest)
            }
            try context.save()
        }
    }

    func removeEvents(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "ItemReadEventEntity")
        fetchRequest.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
