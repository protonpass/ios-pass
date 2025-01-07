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
    func getPaginatedNotifications(lastNotificationId: String?, userId: String) async throws
        -> PaginatedInAppNotifications
    func changeNotificationStatus(notificationId: String,
                                  newStatus: InAppNotificationState,
                                  userId: String) async throws
    func remove(notificationId: String, userId: String) async throws
    func upsertNotifications(_ notifications: [InAppNotification], userId: String) async throws
    func removeAllNotifications(userId: String) async throws
}

public actor InAppNotificationRepository: InAppNotificationRepositoryProtocol {
    private let localDatasource: any LocalInAppNotificationDatasourceProtocol
    private let remoteDatasource: any RemoteInAppNotificationDatasourceProtocol
    private let logger: Logger

    public init(localDatasource: any LocalInAppNotificationDatasourceProtocol,
                remoteDatasource: any RemoteInAppNotificationDatasourceProtocol,
                logManager: any LogManagerProtocol) {
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
        logger = .init(manager: logManager)
    }

    public func getPaginatedNotifications(lastNotificationId: String?,
                                          userId: String) async throws -> PaginatedInAppNotifications {
        logger.trace("Fetching all user remote in app notification for user id: \(userId)")
        let notifs = try await remoteDatasource.getNotifications(lastNotificationId: lastNotificationId,
                                                                 userId: userId)
        return notifs
    }

    public func changeNotificationStatus(notificationId: String,
                                         newStatus: InAppNotificationState,
                                         userId: String) async throws {
        try await remoteDatasource.changeNotificationStatus(notificationId: notificationId,
                                                            newStatus: newStatus,
                                                            userId: userId)
    }

    public func upsertNotifications(_ notifications: [InAppNotification], userId: String) async throws {
        try await localDatasource.upsertNotifications(notifications, userId: userId)
    }

    public func remove(notificationId: String, userId: String) async throws {
        try await localDatasource.remove(notificationId: notificationId, userId: userId)
    }

    public func removeAllNotifications(userId: String) async throws {
        try await localDatasource.removeAllNotifications(userId: userId)
    }
}
