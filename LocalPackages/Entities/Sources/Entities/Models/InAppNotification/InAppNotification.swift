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

import Foundation

public struct InAppNotification: Decodable, Sendable, Equatable, Hashable, Identifiable {
    public let ID: String
    public let notificationKey: String
    public let startTime: Int
    public let endTime: Int?
    /// Prefer using `safeState` for clearer semantic
    public var state: Int
    public let priority: Int
    public let content: InAppNotificationContent

    public init(ID: String,
                notificationKey: String,
                startTime: Int,
                endTime: Int?,
                state: Int,
                priority: Int,
                content: InAppNotificationContent) {
        self.ID = ID
        self.notificationKey = notificationKey
        self.startTime = startTime
        self.endTime = endTime
        self.state = state
        self.priority = priority
        self.content = content
    }

    public var id: String {
        // swiftformat:disable:next redundantSelf
        self.ID
    }

    public var displayType: InAppNotificationDisplayType {
        content.safeDisplayType
    }

    public var safeState: InAppNotificationState {
        .init(rawValue: state) ?? .unread
    }

    public var hasBeenRead: Bool {
        safeState != InAppNotificationState.unread
    }

    public var ctaType: InAppNotificationCtaType? {
        guard let cta = content.cta else { return nil }
        if cta.type == "internal_navigation" {
            return .internalNavigation(cta.ref)
        } else {
            return .externalNavigation(cta.ref)
        }
    }

    public var removedState: InAppNotificationState {
        if displayType == .banner {
            .read
        } else {
            .dismissed
        }
    }
}

public struct InAppNotificationContent: Decodable, Sendable, Equatable, Hashable {
    public let imageUrl: String?
    /// Prefer using `safeDisplayType` for clearer semantic
    private let displayType: Int
    public let title: String
    public let message: String
    // Can be light or dark
    public let theme: String?
    public let cta: InAppNotificationCTA?
    public let promoContents: InAppNotificationPromoContents?

    public var safeImageUrl: URL? {
        if let imageUrl, let url = URL(string: imageUrl) {
            return url
        }
        return nil
    }

    public var safeDisplayType: InAppNotificationDisplayType {
        .init(rawValue: displayType) ?? .banner
    }

    public init(imageUrl: String?,
                displayType: Int,
                title: String,
                message: String,
                theme: String?,
                cta: InAppNotificationCTA?,
                promoContents: InAppNotificationPromoContents?) {
        self.imageUrl = imageUrl
        self.displayType = displayType
        self.title = title
        self.message = message
        self.theme = theme
        self.cta = cta
        self.promoContents = promoContents
    }
}

public struct InAppNotificationCTA: Decodable, Sendable, Equatable, Hashable {
    public let text: String
    // Action of the CTA. Can be either external_link | internal_navigation
    public let type: String
    // Destination of the CTA. If type=external_link, it's a URL. If type=internal_navigation, it's a deeplink
    public let ref: String

    public init(text: String, type: String, ref: String) {
        self.text = text
        self.type = type
        self.ref = ref
    }
}

public enum InAppNotificationCtaType: Sendable {
    case internalNavigation(String)
    case externalNavigation(String)
}

public enum InAppNotificationDisplayType: Int, Sendable {
    /// Floating bottom banner
    case banner = 0
    /// Bottom sheet with dynamic height fitting its content
    case modal = 1
    /// Customized for promos (full screen cover on iPhone, full height sheet on iPad)
    case promo = 2
}

public enum InAppNotificationState: Int, Sendable {
    case unread = 0
    case read = 1
    // Dismissed is the equivalent of delete for the back end should be used with modal
    case dismissed = 2
}

public struct InAppNotificationPromoContents: Decodable, Sendable, Equatable, Hashable {
    /// Whether the promo should start minimized.
    /// `true` means the image should be minimized from the start.
    /// `false` means that the promo should initially be displayed and the user can minimize.
    public let startMinimized: Bool
    /// Text to show on the close promo link
    public let closePromoText: String
    /// Text to show when the promo is minimized
    public let minimizedPromoText: String
    public let lightThemeContents: InAppNotificationPromoThemedContents
    public let darkThemeContents: InAppNotificationPromoThemedContents

    public init(startMinimized: Bool,
                closePromoText: String,
                minimizedPromoText: String,
                lightThemeContents: InAppNotificationPromoThemedContents,
                darkThemeContents: InAppNotificationPromoThemedContents) {
        self.startMinimized = startMinimized
        self.closePromoText = closePromoText
        self.minimizedPromoText = minimizedPromoText
        self.lightThemeContents = lightThemeContents
        self.darkThemeContents = darkThemeContents
    }
}

public struct InAppNotificationPromoThemedContents: Decodable, Sendable, Equatable, Hashable {
    public let backgroundImageUrl: String
    public let contentImageUrl: String
    public let closePromoTextColor: String

    public init(backgroundImageUrl: String,
                contentImageUrl: String,
                closePromoTextColor: String) {
        self.backgroundImageUrl = backgroundImageUrl
        self.contentImageUrl = contentImageUrl
        self.closePromoTextColor = closePromoTextColor
    }
}
