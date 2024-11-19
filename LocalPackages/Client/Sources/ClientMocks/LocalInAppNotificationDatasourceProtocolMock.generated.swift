// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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

import Client
import CoreData
import Entities

public final class LocalInAppNotificationDatasourceProtocolMock: @unchecked Sendable, LocalInAppNotificationDatasourceProtocol {

    public init() {}

    // MARK: - getAllNotificationsByPriority
    public var getAllNotificationsByPriorityUserIdThrowableError1: Error?
    public var closureGetAllNotificationsByPriority: () -> () = {}
    public var invokedGetAllNotificationsByPriorityfunction = false
    public var invokedGetAllNotificationsByPriorityCount = 0
    public var invokedGetAllNotificationsByPriorityParameters: (userId: String, Void)?
    public var invokedGetAllNotificationsByPriorityParametersList = [(userId: String, Void)]()
    public var stubbedGetAllNotificationsByPriorityResult: [InAppNotification]!

    public func getAllNotificationsByPriority(userId: String) async throws -> [InAppNotification] {
        invokedGetAllNotificationsByPriorityfunction = true
        invokedGetAllNotificationsByPriorityCount += 1
        invokedGetAllNotificationsByPriorityParameters = (userId, ())
        invokedGetAllNotificationsByPriorityParametersList.append((userId, ()))
        if let error = getAllNotificationsByPriorityUserIdThrowableError1 {
            throw error
        }
        closureGetAllNotificationsByPriority()
        return stubbedGetAllNotificationsByPriorityResult
    }
    // MARK: - upsertNotifications
    public var upsertNotificationsUserIdThrowableError2: Error?
    public var closureUpsertNotifications: () -> () = {}
    public var invokedUpsertNotificationsfunction = false
    public var invokedUpsertNotificationsCount = 0
    public var invokedUpsertNotificationsParameters: (notifications: [InAppNotification], userId: String)?
    public var invokedUpsertNotificationsParametersList = [(notifications: [InAppNotification], userId: String)]()

    public func upsertNotifications(_ notifications: [InAppNotification], userId: String) async throws {
        invokedUpsertNotificationsfunction = true
        invokedUpsertNotificationsCount += 1
        invokedUpsertNotificationsParameters = (notifications, userId)
        invokedUpsertNotificationsParametersList.append((notifications, userId))
        if let error = upsertNotificationsUserIdThrowableError2 {
            throw error
        }
        closureUpsertNotifications()
    }
    // MARK: - removeAllNotifications
    public var removeAllNotificationsUserIdThrowableError3: Error?
    public var closureRemoveAllNotifications: () -> () = {}
    public var invokedRemoveAllNotificationsfunction = false
    public var invokedRemoveAllNotificationsCount = 0
    public var invokedRemoveAllNotificationsParameters: (userId: String, Void)?
    public var invokedRemoveAllNotificationsParametersList = [(userId: String, Void)]()

    public func removeAllNotifications(userId: String) async throws {
        invokedRemoveAllNotificationsfunction = true
        invokedRemoveAllNotificationsCount += 1
        invokedRemoveAllNotificationsParameters = (userId, ())
        invokedRemoveAllNotificationsParametersList.append((userId, ()))
        if let error = removeAllNotificationsUserIdThrowableError3 {
            throw error
        }
        closureRemoveAllNotifications()
    }
    // MARK: - remove
    public var removeNotificationIdUserIdThrowableError4: Error?
    public var closureRemove: () -> () = {}
    public var invokedRemovefunction = false
    public var invokedRemoveCount = 0
    public var invokedRemoveParameters: (notificationId: String, userId: String)?
    public var invokedRemoveParametersList = [(notificationId: String, userId: String)]()

    public func remove(notificationId: String, userId: String) async throws {
        invokedRemovefunction = true
        invokedRemoveCount += 1
        invokedRemoveParameters = (notificationId, userId)
        invokedRemoveParametersList.append((notificationId, userId))
        if let error = removeNotificationIdUserIdThrowableError4 {
            throw error
        }
        closureRemove()
    }
}
