//
// RemoteInAppNotificationDatasource.swift
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

import Entities

public protocol RemoteInAppNotificationDatasourceProtocol: Sendable {
    func getNotifications(userId: String,
                          countryCode: String?,
                          lastNotificationId: String?) async throws -> PaginatedInAppNotifications
    func changeNotificationStatus(notificationId: String,
                                  newStatus: InAppNotificationState,
                                  userId: String) async throws
}

public final class RemoteInAppNotificationDatasource: RemoteDatasource, RemoteInAppNotificationDatasourceProtocol,
    @unchecked Sendable {
    public func getNotifications(userId: String,
                                 countryCode: String?,
                                 lastNotificationId: String?) async throws -> PaginatedInAppNotifications {
        let endpoint = GetInAppNotificationsEndpoint(countryCode: countryCode,
                                                     lastNotificationId: lastNotificationId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.notifications
    }

    public func changeNotificationStatus(notificationId: String,
                                         newStatus: InAppNotificationState,
                                         userId: String) async throws {
        let endpoint = ChangeInAppNotificationStatusEndpoint(notificationId: notificationId,
                                                             state: newStatus.rawValue)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }
}
