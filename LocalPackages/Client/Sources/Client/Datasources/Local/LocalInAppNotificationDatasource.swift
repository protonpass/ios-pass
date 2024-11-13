//
// LocalInAppNotificationDatasource.swift
// Proton Pass - Created on 08/11/2024.
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

// sourcery: AutoMockable
public protocol LocalInAppNotificationDatasourceProtocol: Sendable {
    func getAllNotificationsByPriority(userId: String) async throws -> [InAppNotification]
    func upsertInAppNotification(_ notification: [InAppNotification], userId: String) async throws
    func removeAllInAppNotifications(userId: String) async throws
    func remove(notificationId: String) async throws
}

public final class LocalInAppNotificationDatasource: LocalDatasource, LocalInAppNotificationDatasourceProtocol,
    @unchecked Sendable {}

public extension LocalInAppNotificationDatasource {
    func getAllNotificationsByPriority(userId: String) async throws -> [InAppNotification] {
        let taskContext = newTaskContext(type: .fetch)
        let fetchRequest = InAppNotificationEntity.fetchRequest()

        fetchRequest.predicate = .init(format: "userId = %@", userId)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "priority", ascending: false)]
        let inAppNotificationEntities = try await execute(fetchRequest: fetchRequest, context: taskContext)
        return inAppNotificationEntities.map { $0.toInAppNotification() }
    }

    func upsertInAppNotification(_ notification: [InAppNotification], userId: String) async throws {
        try await upsert(notification,
                         entityType: InAppNotificationEntity.self,
                         fetchPredicate: NSPredicate(format: "userId = %@", userId),
                         isEqual: { item, entity in
                             item.id == entity.id
                         },
                         hydrate: { item, entity in
                             entity.hydrate(from: item, userId: userId)
                         })
    }

    func removeAllInAppNotifications(userId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "InAppNotificationEntity")
        fetchRequest.predicate = .init(format: "userId = %@", userId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }

    func remove(notificationId: String) async throws {
        let taskContext = newTaskContext(type: .delete)
        let fetchRequest = NSFetchRequest<any NSFetchRequestResult>(entityName: "InAppNotificationEntity")
        fetchRequest.predicate = .init(format: "id = %@", notificationId)
        try await execute(batchDeleteRequest: .init(fetchRequest: fetchRequest),
                          context: taskContext)
    }
}
