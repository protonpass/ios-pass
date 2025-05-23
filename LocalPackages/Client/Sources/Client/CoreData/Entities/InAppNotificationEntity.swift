//
// InAppNotificationEntity.swift
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

import CoreData
import Entities

@objc(InAppNotificationEntity)
final class InAppNotificationEntity: NSManagedObject {}

extension InAppNotificationEntity: Identifiable {}

extension InAppNotificationEntity {
    @nonobjc
    public class func fetchRequest() -> NSFetchRequest<InAppNotificationEntity> {
        NSFetchRequest<InAppNotificationEntity>(entityName: "InAppNotificationEntity")
    }

    @NSManaged var userId: String
    @NSManaged var id: String
    @NSManaged var notificationKey: String
    @NSManaged var startTime: Int64
    @NSManaged var endTime: Int64
    @NSManaged var state: Int64
    @NSManaged var imageUrl: String?
    @NSManaged var displayType: Int64
    @NSManaged var title: String
    @NSManaged var message: String
    @NSManaged var theme: String?
    @NSManaged var hasCta: Bool
    @NSManaged var ctaText: String?
    @NSManaged var ctaType: String?
    @NSManaged var ctaRef: String?
    @NSManaged var priority: Int64
}

extension InAppNotificationEntity {
    func toInAppNotification() -> InAppNotification {
        let cta: InAppNotificationCTA? = if hasCta, let ctaRef, let ctaText, let ctaType {
            InAppNotificationCTA(text: ctaText, type: ctaType, ref: ctaRef)
        } else {
            nil
        }

        let content = InAppNotificationContent(imageUrl: imageUrl,
                                               displayType: Int(displayType),
                                               title: title,
                                               message: message,
                                               theme: theme,
                                               cta: cta)
        return InAppNotification(ID: id,
                                 notificationKey: notificationKey,
                                 startTime: Int(startTime),
                                 endTime: endTime == -1 ? nil : Int(endTime),
                                 state: Int(state),
                                 priority: Int(priority),
                                 content: content)
    }

    func hydrate(from notification: InAppNotification, userId: String) {
        self.userId = userId
        id = notification.id
        notificationKey = notification.notificationKey
        startTime = Int64(notification.startTime)
        endTime = Int64(notification.endTime ?? -1)
        state = Int64(notification.state)
        imageUrl = notification.content.imageUrl
        displayType = Int64(notification.content.displayType)
        title = notification.content.title
        message = notification.content.message
        theme = notification.content.theme
        hasCta = notification.content.cta != nil
        ctaRef = notification.content.cta?.ref
        ctaText = notification.content.cta?.text
        ctaType = notification.content.cta?.type
        priority = Int64(notification.priority)
    }
}
