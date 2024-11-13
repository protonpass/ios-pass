//
// InAppNotificationManager.swift
// Proton Pass - Created on 07/11/2024.
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

import Combine
import Core
import Entities
import Foundation

private let kInAppNotificationTimerKey = "InAppNotificationTimer"

public protocol InAppNotificationManagerProtocol: Sendable {
    var notifications: [InAppNotification] { get }

    func fetchNotifications(offsetId: String?, reset: Bool) async throws -> [InAppNotification]
    func getNotificationToDisplay() async throws -> InAppNotification?
    func updateNotificationState(notificationId: String, newState: InAppNotificationState) async throws
}

public extension InAppNotificationManagerProtocol {
    func fetchNotifications(offsetId: String? = nil, reset: Bool = true) async throws -> [InAppNotification] {
        try await fetchNotifications(offsetId: offsetId, reset: reset)
    }
}

public actor InAppNotificationManager: @preconcurrency InAppNotificationManagerProtocol {
    private let repository: any InAppNotificationRepositoryProtocol
    private let userDefault: UserDefaults
    private let userManager: any UserManagerProtocol
    private let logger: Logger
    public private(set) var notifications: [InAppNotification] = []
    private var lastId: String?

    private nonisolated(unsafe) var cancellables: Set<AnyCancellable> = []
    private nonisolated(unsafe) var task: Task<Void, Never>?

    public init(repository: any InAppNotificationRepositoryProtocol,
                userManager: any UserManagerProtocol,
                userDefault: UserDefaults,
                logManager: any LogManagerProtocol) {
        self.userDefault = userDefault
        self.repository = repository
        self.userManager = userManager
        logger = .init(manager: logManager)
    }

    public func fetchNotifications(offsetId: String? = nil,
                                   reset: Bool = true) async throws -> [InAppNotification] {
        let userId = try await userManager.getActiveUserId()
        let paginatedNotifications = try await repository
            .getPaginatedNotifications(lastNotificationId: offsetId,
                                       userId: userId)
        lastId = paginatedNotifications.lastID
        if reset {
            notifications = paginatedNotifications.notifications
        } else {
            notifications.append(contentsOf: paginatedNotifications.notifications)
        }
        try await repository.removeAllInAppNotifications(userId: userId)
        try await repository.upsertInAppNotification(notifications, userId: userId)
        return notifications
    }

    public func getNotificationToDisplay() async throws -> InAppNotification? {
        guard shouldDisplayNotifications else {
            return nil
        }
        let timestampDate = Date().timeIntervalSinceNow
        updateTime(timestampDate)
        return notifications.filter { notification in
            guard !notification.hasBeenRead,
                  notification.startTime <= timestampDate,
                  (notification.endTime ?? .infinity) >= timestampDate
            else {
                return false
            }
            return true
        }.max(by: { $0.priority < $1.priority })
    }

    public func updateNotificationState(notificationId: String, newState: InAppNotificationState) async throws {
        let userId = try await userManager.getActiveUserId()
        try await repository.changeNotificationStatus(notificationId: notificationId,
                                                      newStatus: newState.rawValue,
                                                      userId: userId)
        if newState == .dismissed {
            try await repository.remove(notificationId: notificationId)
        }
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].state = newState.rawValue
        }
    }
}

private extension InAppNotificationManager {
    func setup() {
        Task {
            do {
                let userId = try await userManager.getActiveUserId()
                notifications = try await repository.getNotifications(userId: userId)
            } catch {
                logger.error(message: "Could not load local in app notifications", error: error)
            }
        }

        userManager.currentActiveUser
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                task?.cancel()
                task = Task { [weak self] in
                    guard let self else { return }
                    _ = try? await fetchNotifications()
                }
            }
            .store(in: &cancellables)
    }

    /// Display notification at most once every 30 minutes
    /// - Returns: A bool equals to `true` when there is more than 30 minutes past since last notification
    /// displayed
    var shouldDisplayNotifications: Bool {
        guard let timeInterval = getTimeForLastNotificationDisplay() else {
            return true
        }
        return timeInterval > 1_800
    }

    func getTimeForLastNotificationDisplay() -> Double? {
        userDefault.double(forKey: kInAppNotificationTimerKey)
    }

    func updateTime(_ time: Double) {
        userDefault.set(time, forKey: kInAppNotificationTimerKey)
    }

    func removeTime() {
        userDefault.removeObject(forKey: kInAppNotificationTimerKey)
    }
}
