//
// TelemetryEventRepositoryTests.swift
// Proton Pass - Created on 25/04/2023.
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

@testable import Client
import Core
import ProtonCore_Services
import XCTest

private final class MockedRemoteDatasource: RemoteTelemetryEventDatasourceProtocol {
    let apiService = PMAPIService.dummyService()

    func send(events: [EventInfo]) async throws {}
}

private final class MockedCurrentDateProvider: CurrentDateProviderProtocol {
    var currentDate = Date.now

    func getCurrentDate() -> Date { currentDate }
}

private final class MockedFreeUserPlanProvider: UserPlanProviderProtocol {
    let apiService = PMAPIService.dummyService()
    let logger = Logger.dummyLogger()

    func getUserPlan() async throws -> UserPlan { .free }
}

final class TelemetryEventRepositoryTests: XCTestCase {
    var localDatasource: LocalTelemetryEventDatasourceProtocol!
    var preferences: Preferences!
    var sut: TelemetryEventRepositoryProtocol!

    override func setUp() {
        super.setUp()
        localDatasource = LocalTelemetryEventDatasource(
            container: .Builder.build(name: kProtonPassContainerName, inMemory: true))
        preferences = .init()
    }

    override func tearDown() {
        localDatasource = nil
        preferences.reset()
        sut = nil
        super.tearDown()
    }
}

extension TelemetryEventRepositoryTests {
    func testAddNewEvents() async throws {
        // Given
        let givenUserId = String.random()
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: CurrentDateProvider(),
                                                    preferences: preferences)
        sut = TelemetryEventRepository(localTelemetryEventDatasource: localDatasource,
                                       remoteTelemetryEventDatasource: MockedRemoteDatasource(),
                                       userPlanProvider: MockedFreeUserPlanProvider(),
                                       eventCount: 100,
                                       logManager: .dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userId: givenUserId)

        // When
        try await sut.addNewEvent(type: .create(.login))
        try await sut.addNewEvent(type: .read(.alias))
        try await sut.addNewEvent(type: .update(.note))
        try await sut.addNewEvent(type: .delete(.login))
        let events = try await localDatasource.getOldestEvents(count: 100, userId: givenUserId)

        // Then
        XCTAssertEqual(events.count, 4)
        XCTAssertEqual(events[0].type, .create(.login))
        XCTAssertEqual(events[1].type, .read(.alias))
        XCTAssertEqual(events[2].type, .update(.note))
        XCTAssertEqual(events[3].type, .delete(.login))
    }

    func testAutoGenerateThresholdWhenCurrentThresholdIsNil() async throws {
        // Given
        let givenUserId = String.random()
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: CurrentDateProvider(),
                                                    preferences: preferences)
        sut = TelemetryEventRepository(localTelemetryEventDatasource: localDatasource,
                                       remoteTelemetryEventDatasource: MockedRemoteDatasource(),
                                       userPlanProvider: MockedFreeUserPlanProvider(),
                                       eventCount: 100,
                                       logManager: .dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userId: givenUserId)
        XCTAssertNil(sut.scheduler.threshhold)

        // When
        let isSent = try await sut.sendAllEventsIfApplicable()

        // Then
        XCTAssertNotNil(sut.scheduler.threshhold)
        XCTAssertFalse(isSent)
    }

    func testDoNotSendEventWhenThresholdNotReached() async throws {
        // Given
        let givenUserId = String.random()

        let givenCurrentDate = Date.now
        let mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        preferences.telemetryThreshold = givenCurrentDate.addingTimeInterval(1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    preferences: preferences)
        sut = TelemetryEventRepository(localTelemetryEventDatasource: localDatasource,
                                       remoteTelemetryEventDatasource: MockedRemoteDatasource(),
                                       userPlanProvider: MockedFreeUserPlanProvider(),
                                       eventCount: 100,
                                       logManager: .dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userId: givenUserId)

        // When
        let isSent = try await sut.sendAllEventsIfApplicable()

        // Then
        XCTAssertFalse(isSent)
    }

    func testSendAllEventsAndRandomNewThresholdIfThresholdIsReached() async throws {
        // Given
        let givenUserId = String.random()

        let givenCurrentDate = Date.now
        let mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        preferences.telemetryThreshold = givenCurrentDate.addingTimeInterval(-1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    preferences: preferences)
        // Send only 1 event at a time to test if the while loop inside TelemetryEventRepository
        // works correctly when dealing with a large number of events
        sut = TelemetryEventRepository(localTelemetryEventDatasource: localDatasource,
                                       remoteTelemetryEventDatasource: MockedRemoteDatasource(),
                                       userPlanProvider: MockedFreeUserPlanProvider(),
                                       eventCount: 1,
                                       logManager: .dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userId: givenUserId)

        // When
        try await sut.addNewEvent(type: .create(.login))
        try await sut.addNewEvent(type: .read(.alias))
        try await sut.addNewEvent(type: .update(.note))
        try await sut.addNewEvent(type: .delete(.login))

        let isSent = try await sut.sendAllEventsIfApplicable()
        let events = try await localDatasource.getOldestEvents(count: 100, userId: givenUserId)
        let newThreshold = try XCTUnwrap(telemetryScheduler.threshhold)
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenCurrentDate,
                                                         to: newThreshold)
        let differenceInHours = try XCTUnwrap(difference.hour)

        // Then
        XCTAssertTrue(isSent)
        XCTAssertTrue(events.isEmpty) // No more events left in local db
        XCTAssertTrue(differenceInHours >= telemetryScheduler.minIntervalInHours)
        XCTAssertTrue(differenceInHours <= telemetryScheduler.maxIntervalInHours)
    }
}
