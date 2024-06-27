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
import ClientMocks
import Combine
import Core
import Entities
import XCTest
import ProtonCoreLogin
import ProtonCoreNetworking

private final class MockedRemoteDatasource: RemoteTelemetryEventDatasourceProtocol {
    func send(events: [EventInfo]) async throws {}
}

private final class MockedCurrentDateProvider: CurrentDateProviderProtocol {
    var currentDate = Date.now

    func getCurrentDate() -> Date { currentDate }
}

private final class MockedUserSettingsRepositoryProtocol: UserSettingsRepositoryProtocol {

    static let defaultSettings = UserSettings(
        telemetry: true,
        highSecurity: HighSecurity.default,
        password: .init(mode: .singlePassword),
        twoFactor: .init(type: .disabled)
    )

    var settings = defaultSettings

    init(settings: UserSettings = defaultSettings) {
        self.settings = settings
    }
   
    func getSettings(for id: String)  async -> UserSettings {
        settings
    }
    
    func updateSettings(settings: UserSettings) async {
        self.settings = settings
    }
    
    func refreshSettings(for id: String) async throws {
        
    }
    
    func toggleSentinel(for id: String) async throws -> Bool {
        return true
    }
}

private final class MockedFreePlanRepository: AccessRepositoryProtocol {
    let access: CurrentValueSubject<Access?, Never> = .init(nil)
    let didUpdateToNewPlan: PassthroughSubject<Void, Never> = .init()

    let mockedAccess = Access(plan: .init(type: "free",
                                          internalName: .random(),
                                          displayName: .random(),
                                          hideUpgrade: false,
                                          trialEnd: .random(in: 1...100),
                                          vaultLimit: .random(in: 1...100),
                                          aliasLimit: .random(in: 1...100),
                                          totpLimit: .random(in: 1...100)),
                              monitor: .init(protonAddress: .random(), aliases: .random()),
                              pendingInvites: 1,
                              waitingNewUserInvites: 1,
                              minVersionUpgrade: nil)

    func getAccess() async throws -> Access { mockedAccess }
    func getPlan() async throws -> Plan { mockedAccess.plan }
    func refreshAccess() async throws -> Access { mockedAccess }
    func updateProtonAddressesMonitor(_ monitored: Bool) async throws {}
    func updateAliasesMonitor(_ monitored: Bool) async throws {}
}

private final class MockedBusinessPlanRepository: AccessRepositoryProtocol {
    let access: CurrentValueSubject<Access?, Never> = .init(nil)
    let didUpdateToNewPlan: PassthroughSubject<Void, Never> = .init()

    let mockedAccess = Access(plan: .init(type: "business",
                                          internalName: .random(),
                                          displayName: .random(),
                                          hideUpgrade: false,
                                          trialEnd: .random(in: 1...100),
                                          vaultLimit: .random(in: 1...100),
                                          aliasLimit: .random(in: 1...100),
                                          totpLimit: .random(in: 1...100)),
                              monitor: .init(protonAddress: .random(), aliases: .random()),
                              pendingInvites: 1,
                              waitingNewUserInvites: 1,
                              minVersionUpgrade: nil)

    func getAccess() async throws -> Access { mockedAccess }
    func getPlan() async throws -> Plan { mockedAccess.plan }
    func refreshAccess() async throws -> Access { mockedAccess }
    func updateProtonAddressesMonitor(_ monitored: Bool) async throws {}
    func updateAliasesMonitor(_ monitored: Bool) async throws {}
}

final class TelemetryEventRepositoryTests: XCTestCase {
    var localDatasource: LocalTelemetryEventDatasourceProtocol!
    var thresholdProvider: TelemetryThresholdProviderMock!
    var userManager: UserManagerProtocolMock!
    var itemReadEventRepository: ItemReadEventRepositoryProtocolMock!
    var sut: TelemetryEventRepositoryProtocol!

    override func setUp() {
        super.setUp()
        localDatasource = LocalTelemetryEventDatasource(databaseService: DatabaseService(inMemory: true))
        thresholdProvider = TelemetryThresholdProviderMock()
        userManager = UserManagerProtocolMock()
        let user = UserData.preview
        userManager.stubbedGetActiveUserIdResult = user.user.ID
        itemReadEventRepository = .init()
    }

    override func tearDown() {
        localDatasource = nil
        thresholdProvider = nil
        userManager = nil
        sut = nil
        super.tearDown()
    }
}

extension TelemetryEventRepositoryTests {
    func testAddNewEvents() async throws {
        // Given
        let givenUserId = try await userManager.getActiveUserId()
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: CurrentDateProvider(),
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: MockedUserSettingsRepositoryProtocol(),
                                       accessRepository: MockedFreePlanRepository(), 
                                       itemReadEventRepository: itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager)

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
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: CurrentDateProvider(),
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: MockedUserSettingsRepositoryProtocol(),
                                       accessRepository: MockedFreePlanRepository(), 
                                       itemReadEventRepository: itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager)
        var threshold = await sut.scheduler.getThreshold()
        XCTAssertNil(threshold)

        // When
        let sendResult = try await sut.sendAllEventsIfApplicable()

        // Then
        threshold = await sut.scheduler.getThreshold()
        XCTAssertNotNil(threshold)
        XCTAssertEqual(sendResult, .thresholdNotReached)
        // Not applicable to free users
        XCTAssertFalse(itemReadEventRepository.invokedSendAllEventsfunction)
    }

    func testDoNotSendEventWhenThresholdNotReached() async throws {
        // Given
        let givenCurrentDate = Date.now
        let mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: MockedUserSettingsRepositoryProtocol(),
                                       accessRepository: MockedFreePlanRepository(), 
                                       itemReadEventRepository: itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager)

        // When
        let sendResult = try await sut.sendAllEventsIfApplicable()

        // Then
        XCTAssertEqual(sendResult, .thresholdNotReached)
        // Not applicable to free users
        XCTAssertFalse(itemReadEventRepository.invokedSendAllEventsfunction)
    }

    func testSendAllEventsAndRandomNewThresholdIfThresholdIsReached() async throws {
        // Given
        let givenUserId = try await userManager.getActiveUserId()
        let givenCurrentDate = Date.now
        let mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(-1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)
        // Send only 1 event at a time to test if the while loop inside TelemetryEventRepository
        // works correctly when dealing with a large number of events
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: MockedUserSettingsRepositoryProtocol(),
                                       accessRepository: MockedFreePlanRepository(),
                                       itemReadEventRepository: itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager,
                                       batchSize: 1)

        // When
        try await sut.addNewEvent(type: .create(.login))
        try await sut.addNewEvent(type: .read(.alias))
        try await sut.addNewEvent(type: .update(.note))
        try await sut.addNewEvent(type: .delete(.login))

        let sendResult = try await sut.sendAllEventsIfApplicable()
        let events = try await localDatasource.getOldestEvents(count: 100, userId: givenUserId)
        let threshold = await telemetryScheduler.getThreshold()
        let newThreshold = try XCTUnwrap(threshold)
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenCurrentDate,
                                                         to: newThreshold)
        let differenceInHours = try XCTUnwrap(difference.hour)

        // Then
        XCTAssertEqual(sendResult, .allEventsSent)
        XCTAssertTrue(events.isEmpty) // No more events left in local db
        let minInterval = await telemetryScheduler.minIntervalInHours
        let maxInterval = await telemetryScheduler.maxIntervalInHours
        XCTAssertTrue(differenceInHours >= minInterval)
        XCTAssertTrue(differenceInHours <= maxInterval)
        // Not applicable to free users
        XCTAssertFalse(itemReadEventRepository.invokedSendAllEventsfunction)
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
        let settings = UserSettings(telemetry: false, highSecurity: .default, password: .init(mode: .singlePassword), twoFactor: .init(type: .disabled))
        let settingsService = MockedUserSettingsRepositoryProtocol(settings: settings)
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: settingsService,
                                       accessRepository: MockedFreePlanRepository(), 
                                       itemReadEventRepository: itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager)

        // When
        try await sut.addNewEvent(type: .create(.login))
        try await sut.addNewEvent(type: .read(.alias))
        try await sut.addNewEvent(type: .update(.note))
        try await sut.addNewEvent(type: .delete(.login))

        let sendResult = try await sut.sendAllEventsIfApplicable()
        let events = try await localDatasource.getOldestEvents(count: 100, userId: givenUserId)
        let threshold = await telemetryScheduler.getThreshold()
        let newThreshold = try XCTUnwrap(threshold)
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenCurrentDate,
                                                         to: newThreshold)
        let differenceInHours = try XCTUnwrap(difference.hour)

        // Then
        XCTAssertEqual(sendResult, .thresholdReachedButTelemetryOff)
        XCTAssertTrue(events.isEmpty) // No more events left in local db
        let minInterval = await telemetryScheduler.minIntervalInHours
        let maxInterval = await telemetryScheduler.maxIntervalInHours
        XCTAssertTrue(differenceInHours >= minInterval)
        XCTAssertTrue(differenceInHours <= maxInterval)
        // Not applicable to free users
        XCTAssertFalse(itemReadEventRepository.invokedSendAllEventsfunction)
    }

    func testSendItemReadEventsForB2BWhenThresholdIsReachedButTelemetryIsOff() async throws {
        // Given
        let givenCurrentDate = Date.now
        let mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(-1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)
        let settings = UserSettings(telemetry: false,
                                    highSecurity: .default,
                                    password: .init(mode: .singlePassword),
                                    twoFactor: .init(type: .disabled))
        let settingsService = MockedUserSettingsRepositoryProtocol(settings: settings)
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: settingsService,
                                       accessRepository: MockedBusinessPlanRepository(), 
                                       itemReadEventRepository: itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager)

        // When
        let sendResult = try await sut.sendAllEventsIfApplicable()

        // Then
        XCTAssertEqual(sendResult, .thresholdReachedButTelemetryOff)
        XCTAssertTrue(itemReadEventRepository.invokedSendAllEventsfunction)
    }

    func testSendItemReadEventsForB2BWhenThresholdIsReached() async throws {
        // Given
        let givenCurrentDate = Date.now
        let mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(-1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: MockedUserSettingsRepositoryProtocol(),
                                       accessRepository: MockedBusinessPlanRepository(),
                                       itemReadEventRepository: 
                                        itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager,
                                       batchSize: 1)

        // When
        let sendResult = try await sut.sendAllEventsIfApplicable()

        // Then
        XCTAssertEqual(sendResult, .allEventsSent)
        XCTAssertTrue(itemReadEventRepository.invokedSendAllEventsfunction)
    }
}
