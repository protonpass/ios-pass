//
// GetInAppNotificationsResponseTests.swift
// Proton Pass - Created on 12/11/2024.
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

@testable import Client
import Entities
import Testing
import Foundation

@Suite(.tags(.endpoint))
struct GetInAppNotificationsResponseTests {
    @Test("Paginated in app notification decoding")
    func decodeInAppNotification() throws {
        // Given
        let string = """
{
  "Code": 1000,
  "Notifications": {
    "Notifications": [
      {
        "ID": "a1b2c3d4==",
        "NotificationKey": "pass_bf_2024",
        "StartTime": 123456789,
        "EndTime": 123456789,
        "State": 0,
        "Priority": 1,
        "Content": {
          "ImageUrl": "https://example.com/image.jpg",
          "DisplayType": 0,
          "Title": "Some title",
          "Message": "Some message",
          "Theme": "light",
          "Cta": {
            "Text": "Upgrade now",
            "Type": "internal_navigation",
            "Ref": "https://some.kb.article"
          }
        }
      }
    ],
    "Total": 1,
    "LastID": "a1b2c3d4=="
  }
}
"""

        let cta = InAppNotificationCTA(text: "Upgrade now", type: "internal_navigation", ref: "https://some.kb.article")
        let content = InAppNotificationContent(imageUrl: "https://example.com/image.jpg",
                                               displayType: 0,
                                               title: "Some title",
                                               message: "Some message",
                                               theme: "light",
                                               cta: cta)
        let notification = InAppNotification(ID: "a1b2c3d4==",
                                             notificationKey: "pass_bf_2024",
                                             startTime: 123456789,
                                             endTime: 123456789,
                                             state: 0,
                                             priority: 1, content: content)
        let paginatedNotification = PaginatedInAppNotifications(notifications: [notification], total: 1, lastID: "a1b2c3d4==")
        
        let expectedResult = GetInAppNotificationsResponse(notifications: paginatedNotification)

        // When
        let sut = try GetInAppNotificationsResponse.decode(from: string)

        #expect(sut == expectedResult)
    }
}
