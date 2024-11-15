//
// LocalInAppNotificationDatasourceTests.swift
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

@testable import Client
import Entities
import EntitiesMocks
import Foundation
import Testing

@Suite(.tags(.localDatasource))
struct LocalInAppNotificationDatasourceTests {
    let sut: any LocalInAppNotificationDatasourceProtocol

    init() {
        sut = LocalInAppNotificationDatasource(databaseService: DatabaseService(inMemory: true))
    }

    @Test("Get in app notification by userID, sorted by priority descending")
    func get() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        // Creating a mock with all default values
        let defaultNotification = InAppNotification.mock()

        // Creating a mock with some custom values
        let morePrioNotification = InAppNotification.mock(priority: 5)
        let morePrioNotificationForUser2 = InAppNotification.mock(priority: 8)

        try await sut.upsertNotifications([defaultNotification, morePrioNotification], userId: userId1)
        try await sut.upsertNotifications([morePrioNotificationForUser2], userId: userId2)

        // When
        let itemsForUser1 = try await sut.getAllNotificationsByPriority(userId: userId1)

        // Then
        #expect(itemsForUser1.count == 2)
        #expect(itemsForUser1.first == morePrioNotification)
    }

    @Test("Upsert in app notification")
    func upsert() async throws {
        // Given
        let userId = String.random()
        // Creating a mock with all default values
        var defaultNotification = InAppNotification.mock()
        try await sut.upsertNotifications([defaultNotification], userId: userId)

        defaultNotification.state = 1

        // When
        try await sut.upsertNotifications([defaultNotification], userId: userId)
        let items = try await sut.getAllNotificationsByPriority(userId: userId)
        let updatedNotification = try #require(items.first)


        // Then
        #expect(items.count == 1)
        #expect(defaultNotification == updatedNotification)
    }

    @Test("Remove all in app notification for one user")
    func removeAll() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()

        for _ in 0...4 {
            try await sut.givenInsertedInAppNotification(userID: userId1)
            try await sut.givenInsertedInAppNotification(userID: userId2)
        }

        // When
        try await sut.removeAllNotifications(userId: userId1)
        let items1 = try await sut.getAllNotificationsByPriority(userId: userId1)
        let items2 = try await sut.getAllNotificationsByPriority(userId: userId2)

        // Then
        #expect(items1.isEmpty)
        #expect(items2.count == 5)
    }
    
    @Test("Remove one in app notification for one user")
    func removeOne() async throws {
        // Given
        let userId = String.random()

        let defaultNotification = try await sut.givenInsertedInAppNotification(userID: userId)
       
        for _ in 0...4 {
            try await sut.givenInsertedInAppNotification(userID: userId)
        }

        // When
        try await sut.remove(notificationId: defaultNotification.id, userId: userId)
        let items = try await sut.getAllNotificationsByPriority(userId: userId)

        // Then
        #expect(items.count == 5)
        #expect(items.contains(defaultNotification) == false)
    }
}

private extension LocalInAppNotificationDatasourceProtocol {
    @discardableResult
    func givenInsertedInAppNotification(userID: String = .random())
    async throws -> InAppNotification {
        let notification = InAppNotification.mock()
        try await upsertNotifications([notification], userId: userID)
        return notification
    }
}
