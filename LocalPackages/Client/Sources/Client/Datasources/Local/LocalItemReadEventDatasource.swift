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

import Core
import CoreData
import Entities
import Foundation

public protocol LocalItemReadEventDatasourceProtocol: Sendable {
    func insertEvent(_ item: any ItemIdentifiable, userId: String) async throws
    func getAllEvents(userId: String) async throws -> [ItemReadEvent]
    func removeAllEvents(userId: String) async throws
}

public final class LocalItemReadEventDatasource: LocalDatasource, LocalItemReadEventDatasourceProtocol {
    private let currentDateProvider: any CurrentDateProviderProtocol

    init(currentDateProvider: any CurrentDateProviderProtocol,
         databaseService: any DatabaseServiceProtocol) {
        self.currentDateProvider = currentDateProvider
        super.init(databaseService: databaseService)
    }
}

public extension LocalItemReadEventDatasource {
    func insertEvent(_ item: any ItemIdentifiable,
                     userId: String) async throws {
        let context = newTaskContext(type: .insert)

        let date = currentDateProvider.getCurrentDate()
        let event = ItemReadEvent(shareId: item.shareId,
                                  itemId: item.itemId,
                                  timestamp: date.timeIntervalSince1970)
        let request =
            newBatchInsertRequest(entity: ItemReadEventEntity.entity(context: context),
                                  sourceItems: [event]) { managedObject, event in
                (managedObject as? ItemReadEventEntity)?.hydrate(from: event, userId: userId)
            }

        try await execute(batchInsertRequest: request, context: context)
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

    func removeAllEvents(userId: String) async throws {
        let context = newTaskContext(type: .delete)
        let request = NSFetchRequest<any NSFetchRequestResult>(entityName: "ItemReadEventEntity")
        request.predicate = .init(format: "userID = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: request),
                          context: context)
    }
}
