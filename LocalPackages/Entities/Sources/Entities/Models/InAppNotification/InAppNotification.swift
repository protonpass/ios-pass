//
// InAppNotification.swift
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

public struct InAppNotification: Decodable, Sendable, Equatable, Hashable, Identifiable {
    public let ID: String
    public let notificationKey: String
    public let startTime: Double
    public let endTime: Double?
    // Notification state. 0 = Unread, 1 = Read, 2 = Dismissed
    public var state: Int
    public let content: InAppNotificationContent

    public var id: String {
        // swiftformat:disable:next redundantSelf
        self.ID
    }

    public var displayType: InAppNotificationDisplayType {
        if content.displayType == 0 {
            .banner
        } else {
            .modal
        }
    }

    public var hasBeenRead: Bool {
        state != InAppNotificationState.unread.rawValue
    }

    public var cta: CtaType? {
        guard let cta = content.cta else { return nil }
        if cta.type == "internal_navigation" {
            return .internalNavigation
        } else {
            return .externalNavigation(cta.ref)
        }
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
    public let cta: InAppNotificationCTA?
}

public struct InAppNotificationCTA: Decodable, Sendable, Equatable, Hashable {
    public let text: String
    // Action of the CTA. Can be either external_link | internal_navigation
    public let type: String
    // Destination of the CTA. If type=external_link, it's a URL. If type=internal_navigation, it's a deeplink
    public let ref: String
}

public enum CtaType: Sendable {
    case internalNavigation
    case externalNavigation(String?)
}

public enum InAppNotificationDisplayType: Sendable {
    case banner
    case modal
}

public enum InAppNotificationState: Int, Sendable {
    case unread = 0
    case read = 1
    case dismissed = 2
}
