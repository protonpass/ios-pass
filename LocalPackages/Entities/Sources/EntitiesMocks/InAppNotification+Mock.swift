//
// InAppNotification+Mock.swift
// Proton Pass - Created on 13/11/2024.
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

public extension InAppNotification {
    static func mock(ID: String = UUID().uuidString,
                     notificationKey: String = "notification_key",
                     startTime: Int = 0,
                     endTime: Int? = Int(Date().addingTimeInterval(600).timeIntervalSince1970),
                     state: Int = 0,
                     priority: Int = 1,
                     content: InAppNotificationContent = .mock()) -> InAppNotification {
        InAppNotification(ID: ID,
                          notificationKey: notificationKey,
                          startTime: startTime,
                          endTime: endTime,
                          state: state,
                          priority: priority,
                          content: content)
    }
}
public extension InAppNotificationContent {
    static func mock(imageUrl: String = "https://example.com/image.png",
                     displayType: Int = 0,
                     title: String = "Sample Notification",
                     message: String = "This is a sample in-app notification message.",
                     theme: String? = "light",
                     cta: InAppNotificationCTA? = InAppNotificationCTA.mock()) -> InAppNotificationContent {
        InAppNotificationContent(imageUrl: imageUrl,
                                 displayType: 0,
                                 title:  title,
                                 message: message,
                                 theme: theme,
                                 cta: cta)
    }
}

public extension InAppNotificationCTA {
    static func mock(text: String = "Learn More", type: String = "external_link", ref: String = "https://example.com") -> InAppNotificationCTA {
        InAppNotificationCTA(text: text, type: type, ref: ref)
    }
}
