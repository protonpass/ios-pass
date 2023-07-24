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

private final class MockedTelemetryOnUserSettingsDatasource: RemoteUserSettingsDatasourceProtocol {
    let apiService = PMAPIService.dummyService()

    func getUserSettings() async throws -> UserSettings {
        .init(telemetry: true)
    }
}

private final class MockedTelemetryOffUserSettingsDatasource: RemoteUserSettingsDatasourceProtocol {
    let apiService = PMAPIService.dummyService()

    func getUserSettings() async throws -> UserSettings {
        .init(telemetry: false)
    }
}

private final class MockedFreePlanRepository: PassPlanRepositoryProtocol {
    var localDatasource: LocalPassPlanDatasourceProtocol =
    LocalPassPlanDatasource(container: .Builder.build(name: kProtonPassContainerName, inMemory: true))

    var remoteDatasource: RemotePassPlanDatasourceProtocol =
    RemotePassPlanDatasource(apiService: PMAPIService.dummyService())

    weak var delegate: Client.PassPlanRepositoryDelegate?

    var userId: String = ""
    let logger = Logger.dummyLogger()

    var freePlan = PassPlan(type: "free",
                            internalName: .random(),
                            displayName: .random(),
                            hideUpgrade: false,
                            trialEnd: .random(in: 1...100),
                            vaultLimit: .random(in: 1...100),
                            aliasLimit: .random(in: 1...100),
                            totpLimit: .random(in: 1...100))

    func getPlan() async throws -> PassPlan { freePlan }

    func refreshPlan() async throws -> PassPlan { freePlan }
}

final class TelemetryEventRepositoryTests: XCTestCase {
    var localDatasource: LocalTelemetryEventDatasourceProtocol!
    var thresholdProvider: TelemetryThresholdProviderMock!
    var sut: TelemetryEventRepositoryProtocol!

    override func setUp() {
        super.setUp()
        localDatasource = LocalTelemetryEventDatasource(
            container: .Builder.build(name: kProtonPassContainerName, inMemory: true))
        thresholdProvider = TelemetryThresholdProviderMock()
    }

    override func tearDown() {
        localDatasource = nil
        thresholdProvider = nil
        sut = nil
        super.tearDown()
    }
}

extension TelemetryEventRepositoryTests {
    func testAddNewEvents() async throws {
        // Given
        let givenUserId = String.random()
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: CurrentDateProvider(),
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(
            localDatasource: localDatasource,
            remoteDatasource: MockedRemoteDatasource(),
            remoteUserSettingsDatasource: MockedTelemetryOnUserSettingsDatasource(),
            passPlanRepository: MockedFreePlanRepository(),
            logManager: LogManager.dummyLogManager(),
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
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(
            localDatasource: localDatasource,
            remoteDatasource: MockedRemoteDatasource(),
            remoteUserSettingsDatasource: MockedTelemetryOnUserSettingsDatasource(),
            passPlanRepository: MockedFreePlanRepository(),
            logManager: LogManager.dummyLogManager(),
            scheduler: telemetryScheduler,
            userId: givenUserId)
        XCTAssertNil(sut.scheduler.threshhold)

        // When
        let sendResult = try await sut.sendAllEventsIfApplicable()

        // Then
        XCTAssertNotNil(sut.scheduler.threshhold)
        XCTAssertEqual(sendResult, .thresholdNotReached)
    }

    func testDoNotSendEventWhenThresholdNotReached() async throws {
        // Given
        let givenUserId = String.random()

        let givenCurrentDate = Date.now
        let mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(
            localDatasource: localDatasource,
            remoteDatasource: MockedRemoteDatasource(),
            remoteUserSettingsDatasource: MockedTelemetryOnUserSettingsDatasource(),
            passPlanRepository: MockedFreePlanRepository(),
            logManager: LogManager.dummyLogManager(),
            scheduler: telemetryScheduler,
            userId: givenUserId)

        // When
        let sendResult = try await sut.sendAllEventsIfApplicable()

        // Then
        XCTAssertEqual(sendResult, .thresholdNotReached)
    }

    func testSendAllEventsAndRandomNewThresholdIfThresholdIsReached() async throws {
        // Given
        let givenUserId = String.random()

        let givenCurrentDate = Date.now
        let mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(-1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)
        // Send only 1 event at a time to test if the while loop inside TelemetryEventRepository
        // works correctly when dealing with a large number of events
        sut = TelemetryEventRepository(
            localDatasource: localDatasource,
            remoteDatasource: MockedRemoteDatasource(),
            remoteUserSettingsDatasource: MockedTelemetryOnUserSettingsDatasource(),
            passPlanRepository: MockedFreePlanRepository(),
            logManager: LogManager.dummyLogManager(),
            scheduler: telemetryScheduler,
            userId: givenUserId,
            eventCount: 1)

        // When
        try await sut.addNewEvent(type: .create(.login))
        try await sut.addNewEvent(type: .read(.alias))
        try await sut.addNewEvent(type: .update(.note))
        try await sut.addNewEvent(type: .delete(.login))

        let sendResult = try await sut.sendAllEventsIfApplicable()
        let events = try await localDatasource.getOldestEvents(count: 100, userId: givenUserId)
        let newThreshold = try XCTUnwrap(telemetryScheduler.threshhold)
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenCurrentDate,
                                                         to: newThreshold)
        let differenceInHours = try XCTUnwrap(difference.hour)

        // Then
        XCTAssertEqual(sendResult, .allEventsSent)
        XCTAssertTrue(events.isEmpty) // No more events left in local db
        XCTAssertTrue(differenceInHours >= telemetryScheduler.minIntervalInHours)
        XCTAssertTrue(differenceInHours <= telemetryScheduler.maxIntervalInHours)
    }

    func testRemoveAllLocalEventsWhenThresholdIsReachedButTelemetryIsOff() async throws {
        // Given
        let givenUserId = String.random()

        let givenCurrentDate = Date.now
        let mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(-1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(
            localDatasource: localDatasource,
            remoteDatasource: MockedRemoteDatasource(),
            remoteUserSettingsDatasource: MockedTelemetryOffUserSettingsDatasource(),
            passPlanRepository: MockedFreePlanRepository(),
            logManager: LogManager.dummyLogManager(),
            scheduler: telemetryScheduler,
            userId: givenUserId)

        // When
        try await sut.addNewEvent(type: .create(.login))
        try await sut.addNewEvent(type: .read(.alias))
        try await sut.addNewEvent(type: .update(.note))
        try await sut.addNewEvent(type: .delete(.login))

        let sendResult = try await sut.sendAllEventsIfApplicable()
        let events = try await localDatasource.getOldestEvents(count: 100, userId: givenUserId)
        let newThreshold = try XCTUnwrap(telemetryScheduler.threshhold)
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenCurrentDate,
                                                         to: newThreshold)
        let differenceInHours = try XCTUnwrap(difference.hour)

        // Then
        XCTAssertEqual(sendResult, .thresholdReachedButTelemetryOff)
        XCTAssertTrue(events.isEmpty) // No more events left in local db
        XCTAssertTrue(differenceInHours >= telemetryScheduler.minIntervalInHours)
        XCTAssertTrue(differenceInHours <= telemetryScheduler.maxIntervalInHours)
    }
}
