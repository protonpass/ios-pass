//
// InAppNotificationManagerTests.swift
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



@testable import Client
import ClientMocks
import Combine
import Core
import CoreMocks
import CryptoKit
import Entities
import EntitiesMocks
import Foundation
import Testing
//

import XCTest
import Combine

// Mock InAppNotificationRepository
final class MockInAppNotificationRepository: @unchecked Sendable, InAppNotificationRepositoryProtocol {
    var mockNotifications: [InAppNotification] = []
    var mockPaginatedNotifications: PaginatedInAppNotifications = PaginatedInAppNotifications(notifications: [], total: 0, lastID: nil)
    var changeNotificationStatusCalled = false
    var removeCalled = false
    var upsertCalled = false
    var removeAllCalled = false
    
    func getNotifications(userId: String) async throws -> [InAppNotification] {
        return mockNotifications
    }
    
    func getPaginatedNotifications(lastNotificationId: String?, userId: String) async throws -> PaginatedInAppNotifications {
        return mockPaginatedNotifications
    }
    
    func changeNotificationStatus(notificationId: String, newStatus: Int, userId: String) async throws {
        changeNotificationStatusCalled = true
    }
    
    func remove(notificationId: String) async throws {
        removeCalled = true
        mockNotifications.removeAll(where: { $0.id == notificationId})
    }
    
    func upsertInAppNotification(_ notification: [InAppNotification], userId: String) async throws {
        upsertCalled = true
    }
    
    func removeAllInAppNotifications(userId: String) async throws {
        removeAllCalled = true
    }
}


@Suite(.tags(.manager))
struct InAppNotificationManagerTests {
    var manager: InAppNotificationManager!
    var mockRepository: MockInAppNotificationRepository!
    let userManager: UserManagerProtocolMock
    var userDefaults: UserDefaults!
    
        init() {
            userManager = .init()
            userManager.stubbedGetActiveUserDataResult = .preview
            mockRepository = MockInAppNotificationRepository()
            userDefaults = UserDefaults(suiteName: "TestDefaults")
            userDefaults.removePersistentDomain(forName: "TestDefaults")
            
            manager = InAppNotificationManager(repository: mockRepository,
                                               userManager: userManager,
                                               userDefault: userDefaults,
                                               delayBetweenNotifications: 0,
                                               logManager: LogManagerProtocolMock())
        }

    @Test("Fetch notifications with reset of data operations")
    func fetchNotificationsResetsNotifications() async throws {
        // Arrange
        let mockNotification = InAppNotification.mock()
        mockRepository.mockPaginatedNotifications = PaginatedInAppNotifications(notifications: [mockNotification], total: 1, lastID: "last123")
        
        // Act
        let notifications = try await manager.fetchNotifications(reset: true)
        
        // Assert
        #expect(notifications.count == 1)
        #expect(notifications.first?.ID == mockNotification.ID)
        #expect(mockRepository.removeAllCalled == true)
        #expect(mockRepository.upsertCalled == true)
    }
    
    @Test("Fetch notifications appending data operations")
    func fetchNotificationsAppendsNotifications() async throws {
        // Arrange
        let initialNotification = InAppNotification.mock()
      
        mockRepository.mockPaginatedNotifications = PaginatedInAppNotifications(notifications: [initialNotification], total: 1, lastID: "newLastId")
        _ = try await manager.fetchNotifications(reset: false)
        let newNotification = InAppNotification.mock(ID: "newNotification")
        mockRepository.mockPaginatedNotifications = PaginatedInAppNotifications(notifications: [newNotification], total: 1, lastID: "newLastId")
        // Act
        let notifications = try await manager.fetchNotifications(reset: false)
        
        // Assert
        #expect(notifications.count == 2)
        #expect(notifications.last?.ID == newNotification.ID)
    }
    
    @Test("Get the highest prio in app notification to display")
    func getNotificationToDisplayReturnsHighestPriorityUnreadNotification() async throws {
        // Arrange
        let lowPriorityNotification = InAppNotification.mock(state: InAppNotificationState.unread.rawValue, priority: 1)
        let highPriorityNotification = InAppNotification.mock(state: InAppNotificationState.unread.rawValue, priority: 10)
        mockRepository.mockPaginatedNotifications = PaginatedInAppNotifications(notifications: [lowPriorityNotification, highPriorityNotification], total: 2, lastID: "newLastId")
        _ = try await manager.fetchNotifications()

        // Act
        let notificationToDisplay = try await manager.getNotificationToDisplay()
        
        #expect(notificationToDisplay?.ID == highPriorityNotification.ID)
        // Assert
    }
    
    @Test("Test that we don't show any read notification")
    func getNotificationToDisplayReturnsNilWhenAllRead() async throws {
        // Arrange
        let readNotification = InAppNotification.mock(state: InAppNotificationState.read.rawValue, priority: 1)
        mockRepository.mockPaginatedNotifications = PaginatedInAppNotifications(notifications: [readNotification], total: 1, lastID: "newLastId")
        _ = try await manager.fetchNotifications()
        
        // Act
        let notificationToDisplay = try await manager.getNotificationToDisplay()
        
        // Assert
        #expect(notificationToDisplay == nil)

    }
    
    @Test("Test updating the state of notification")
    func testUpdateNotificationStateUpdatesStateAndCallsRepository() async throws {
        // Arrange
        let notificationId = "notification123"
        let notification = InAppNotification.mock(ID: notificationId)
        mockRepository.mockPaginatedNotifications = PaginatedInAppNotifications(notifications: [notification], total: 1, lastID: "newLastId")
        _ = try await manager.fetchNotifications()
        
        // Act
        try await manager.updateNotificationState(notificationId: notificationId, newState: .read)
        
        // Assert
        #expect(mockRepository.changeNotificationStatusCalled == true)
        await #expect(manager.notifications.first?.state == InAppNotificationState.read.rawValue)
    }
    
    @Test("Test updating the state of notification to dimissed removes notification for local storage")
    func testUpdateNotificationStateRemovesNotificationIfDismissed() async throws {
        // Arrange
        let notificationId = "notification123"
        let notification = InAppNotification.mock(ID: notificationId)
        mockRepository.mockPaginatedNotifications = PaginatedInAppNotifications(notifications: [notification], total: 1, lastID: "newLastId")
        _ = try await manager.fetchNotifications()
        
        // Act
        try await manager.updateNotificationState(notificationId: notificationId, newState: .dismissed)
        
        // Assert
        #expect(mockRepository.removeCalled == true)
        await #expect(manager.notifications.first?.state == InAppNotificationState.dismissed.rawValue)
    }
}
