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

import Entities
import Foundation

private let kInAppNotificationTimerKey = "InAppNotificationTimer"

public protocol InAppNotificationManagerProtocol: Sendable {
    var notifications: [InAppNotification] { get }

    func shouldPullNotifications() async -> Bool
    func fetchNotifications(offsetId: String?) async throws -> [InAppNotification]
    func getNotificationToDisplay() async throws -> InAppNotification?
    func updateNotificationState(notificationId: String, newState: InAppNotificationState) async throws
}

public actor InAppNotificationManager: @preconcurrency InAppNotificationManagerProtocol {
    private let repository: any InAppNotificationRepositoryProtocol
    private let userDefault: UserDefaults
    private let userManager: any UserManagerProtocol
    public private(set) var notifications: [InAppNotification] = []
    private var lastId: String?
    private var hasFetchedAtLeastOnce: Bool = false

    public init(repository: any InAppNotificationRepositoryProtocol,
                userManager: any UserManagerProtocol,
                userDefault: UserDefaults) {
        self.userDefault = userDefault
        self.repository = repository
        self.userManager = userManager
    }

    public func fetchNotifications(offsetId: String?) async throws -> [InAppNotification] {
        let userId = try await userManager.getActiveUserId()
        let paginatedNotifications = try await repository
            .getNotifications(lastNotificationId: offsetId,
                              userId: userId)
        lastId = paginatedNotifications.lastID
        notifications.append(contentsOf: paginatedNotifications.notifications)
        hasFetchedAtLeastOnce = true
        updateTime(Date().timeIntervalSinceNow)
        return notifications
    }

    public func getNotificationToDisplay() async throws -> InAppNotification? {
        notifications.first { !$0.hasBeenRead }
    }

    public func shouldPullNotifications() async -> Bool {
        guard hasFetchedAtLeastOnce, let timeInterval = getTimeForLastNotificationPull() else {
            return true
        }
        return timeInterval > 3_600
    }

    public func updateNotificationState(notificationId: String, newState: InAppNotificationState) async throws {
        let userId = try await userManager.getActiveUserId()
        try await repository.changeNotificationStatus(notificationId: notificationId,
                                                      newStatus: newState.rawValue,
                                                      userId: userId)
        if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
            notifications[index].state = newState.rawValue
        }
    }
}

private extension InAppNotificationManager {
    func getTimeForLastNotificationPull() -> Double? {
        userDefault.double(forKey: kInAppNotificationTimerKey)
    }

    func updateTime(_ time: Double) {
        userDefault.set(time, forKey: kInAppNotificationTimerKey)
    }

    func removeTime() {
        userDefault.removeObject(forKey: kInAppNotificationTimerKey)
    }
}
