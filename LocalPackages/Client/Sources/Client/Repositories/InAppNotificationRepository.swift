//
// InAppNotificationRepository.swift
// Proton Pass - Created on 05/11/2024.
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

@preconcurrency import Combine
import Core
import Entities

public protocol InAppNotificationRepositoryProtocol: AnyObject, Sendable {
    func getNotifications(userId: String) async throws -> [InAppNotification]
    func getPaginatedNotifications(lastNotificationId: String?, userId: String) async throws
        -> PaginatedInAppNotifications
    // Notification state. 0 = Unread, 1 = Read, 2 = Dismissed
    func changeNotificationStatus(notificationId: String, newStatus: Int, userId: String) async throws
    func remove(notificationId: String) async throws
    func upsertInAppNotification(_ notification: [InAppNotification], userId: String) async throws
    func removeAllInAppNotifications(userId: String) async throws
}

public actor InAppNotificationRepository: InAppNotificationRepositoryProtocol {
    private let localDatasource: any LocalInAppNotificationDatasourceProtocol
    private let remoteDatasource: any RemoteInAppNotificationDatasourceProtocol
    private let userManager: any UserManagerProtocol
    private let logger: Logger

    public init(localDatasource: any LocalInAppNotificationDatasourceProtocol,
                remoteDatasource: any RemoteInAppNotificationDatasourceProtocol,
                userManager: any UserManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        self.userManager = userManager
        logger = .init(manager: logManager)
    }

    public func getNotifications(userId: String) async throws -> [InAppNotification] {
        logger.trace("Fetching all user in app notification for user id: \(userId)")
        return try await localDatasource.getAllNotificationsByPriority(userId: userId)
    }

    public func getPaginatedNotifications(lastNotificationId: String?,
                                          userId: String) async throws -> PaginatedInAppNotifications {
        let notifs = try await remoteDatasource.getNotifications(lastNotificationId: lastNotificationId,
                                                                 userId: userId)
        return notifs
    }

    public func changeNotificationStatus(notificationId: String, newStatus: Int, userId: String) async throws {
        try await remoteDatasource.changeNotificationStatus(notificationId: notificationId,
                                                            newStatus: newStatus,
                                                            userId: userId)
    }

    public func upsertInAppNotification(_ notification: [InAppNotification], userId: String) async throws {
        try await localDatasource.upsertInAppNotification(notification, userId: userId)
    }

    public func remove(notificationId: String) async throws {
        try await localDatasource.remove(notificationId: notificationId)
    }

    public func removeAllInAppNotifications(userId: String) async throws {
        try await localDatasource.removeAllInAppNotifications(userId: userId)
    }
}
