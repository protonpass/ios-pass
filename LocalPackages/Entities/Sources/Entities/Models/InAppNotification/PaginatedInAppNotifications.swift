//
// PaginatedInAppNotifications.swift
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

public struct PaginatedInAppNotifications: Decodable, Sendable, Equatable, Hashable {
    public let notifications: [InAppNotification]
    public let total: Int
    public let lastID: String?
}

public struct InAppNotification: Decodable, Sendable, Equatable, Hashable, Identifiable {
    public let ID: String
    public let notificationKey: String
    public let startTime: Double
    public let endTime: Double?
    // Notification state. 0 = Unread, 1 = Read, 2 = Dismissed
    public let state: Int
    public let content: InAppNotificationContent

    public var id: String {
        // swiftformat:disable:next redundantSelf
        self.ID
    }
}

public struct InAppNotificationContent: Decodable, Sendable, Equatable, Hashable {
    public let imageUrl: String?
    //    0 = Banner, 1 = Modal.
    //    Banner -> The small bar on the bottom
    //    Modal -> Full screen in your face
    public let displayType: Int
    public let title: String
    public let message: String
    // Can be light or dark
    public let theme: String?
    public let cta: InAppNotificationCTA
}

public struct InAppNotificationCTA: Decodable, Sendable, Equatable, Hashable {
    public let text: String
    // Action of the CTA. Can be either external_link | internal_navigation
    public let type: String
    // Destination of the CTA. If type=external_link, it's a URL. If type=internal_navigation, it's a deeplink
    public let ref: String?
}
