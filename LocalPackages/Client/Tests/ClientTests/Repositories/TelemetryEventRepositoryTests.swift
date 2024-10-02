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
    func send(userId: String, events: [Client.EventInfo]) async throws {}

    func send(events: [EventInfo]) async throws {}
}

private struct MockedCurrentDateProvider: CurrentDateProviderProtocol {
    var currentDate = Date.now
    func getCurrentDate() -> Date { currentDate }
}

final class TelemetryEventRepositoryTests: XCTestCase {
    var localDatasource: LocalTelemetryEventDatasourceProtocol!
    var localAccessDatasource: LocalAccessDatasourceProtocolMock!
    var thresholdProvider: TelemetryThresholdProviderMock!
    var userSettingsRepository: UserSettingsRepositoryProtocolMock!
    var userManager: UserManagerProtocolMock!
    var itemReadEventRepository: ItemReadEventRepositoryProtocolMock!
    var sut: TelemetryEventRepositoryProtocol!

    override func setUp() {
        super.setUp()
        localDatasource = LocalTelemetryEventDatasource(databaseService: DatabaseService(inMemory: true))
        localAccessDatasource = .init()
        thresholdProvider = .init()
        userSettingsRepository = .init()
        userManager = .init()
        userManager.stubbedGetActiveUserDataResult = UserData.preview
        itemReadEventRepository = .init()
    }

    override func tearDown() {
        localDatasource = nil
        thresholdProvider = nil
        userSettingsRepository = nil
        userManager = nil
        localAccessDatasource = nil
        sut = nil
        super.tearDown()
    }
}

extension TelemetryEventRepositoryTests {
    func testAddNewEvents() async throws {
        // Given
        let userId1 = String.random()
        let userId2 = String.random()
        let userId3 = String.random()
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: CurrentDateProvider(),
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: userSettingsRepository,
                                       localAccessDatasource: LocalAccessDatasourceProtocolMock(),
                                       itemReadEventRepository: itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager)

        // When
        try await sut.addNewEvent(userId: userId1, type: .create(.login))
        try await sut.addNewEvent(userId: userId1, type: .read(.alias))
        try await sut.addNewEvent(userId: userId2, type: .update(.note))
        try await sut.addNewEvent(userId: userId3, type: .delete(.login))
        let events1 = try await localDatasource.getOldestEvents(count: 100, userId: userId1)
        let events2 = try await localDatasource.getOldestEvents(count: 100, userId: userId2)
        let events3 = try await localDatasource.getOldestEvents(count: 100, userId: userId3)

        // Then
        XCTAssertEqual(events1.count, 2)
        XCTAssertEqual(events1[0].type, .create(.login))
        XCTAssertEqual(events1[1].type, .read(.alias))

        XCTAssertEqual(events2.count, 1)
        XCTAssertEqual(events2[0].type, .update(.note))

        XCTAssertEqual(events3.count, 1)
        XCTAssertEqual(events3[0].type, .delete(.login))
    }

    func testAutoGenerateThresholdWhenCurrentThresholdIsNil() async throws {
        // Given
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: CurrentDateProvider(),
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: userSettingsRepository,
                                       localAccessDatasource: localAccessDatasource,
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
        XCTAssertFalse(itemReadEventRepository.invokedSendAllEventsfunction)
    }

    func testDoNotSendEventWhenThresholdNotReached() async throws {
        // Given
        let givenCurrentDate = Date.now
        var mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: userSettingsRepository,
                                       localAccessDatasource: localAccessDatasource,
                                       itemReadEventRepository: itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager)

        // When
        let sendResult = try await sut.sendAllEventsIfApplicable()

        // Then
        XCTAssertEqual(sendResult, .thresholdNotReached)
        XCTAssertFalse(itemReadEventRepository.invokedSendAllEventsfunction)
    }

    func testSendAllEventsAndRandomNewThresholdIfThresholdIsReached() async throws {
        // Given
        let user1 = UserData.random()
        let user2 = UserData.random()
        let user3 = UserData.random()

        let userId1 = user1.user.ID
        let userId2 = user2.user.ID
        let userId3 = user3.user.ID

        let givenCurrentDate = Date.now
        var mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        userManager.stubbedGetAllUsersResult = [user1, user2, user3]

        localAccessDatasource.closureGetAccess = { [weak self] in
            guard let self else { return }
            let userId = localAccessDatasource.invokedGetAccessParameters?.0 ?? ""
            let access: UserAccess = switch userId {
            case userId2:
                // Paid user
                    .init(userId: userId2,
                          access: Access(plan: .init(type: "plus",
                                                     internalName: .random(),
                                                     displayName: .random(),
                                                     hideUpgrade: false,
                                                     manageAlias: false,
                                                     trialEnd: .random(in: 1...100),
                                                     vaultLimit: .random(in: 1...100),
                                                     aliasLimit: .random(in: 1...100),
                                                     totpLimit: .random(in: 1...100)),
                                         monitor: .init(protonAddress: .random(), aliases: .random()),
                                         pendingInvites: 1,
                                         waitingNewUserInvites: 1,
                                         minVersionUpgrade: nil, 
                                         userData: UserAliasSyncData.default))
            case userId3:
                // Business user
                    .init(userId: userId3,
                          access: Access(plan: .init(type: "business",
                                                     internalName: .random(),
                                                     displayName: .random(),
                                                     hideUpgrade: false,
                                                     manageAlias: false,
                                                     trialEnd: .random(in: 1...100),
                                                     vaultLimit: .random(in: 1...100),
                                                     aliasLimit: .random(in: 1...100),
                                                     totpLimit: .random(in: 1...100)),
                                         monitor: .init(protonAddress: .random(), aliases: .random()),
                                         pendingInvites: 1,
                                         waitingNewUserInvites: 1,
                                         minVersionUpgrade: nil,
                                         userData: UserAliasSyncData.default))
            default:
                // Free user
                    .init(userId: userId3,
                          access: Access(plan: .init(type: "free",
                                                     internalName: .random(),
                                                     displayName: .random(),
                                                     hideUpgrade: false,
                                                     manageAlias: false,
                                                     trialEnd: .random(in: 1...100),
                                                     vaultLimit: .random(in: 1...100),
                                                     aliasLimit: .random(in: 1...100),
                                                     totpLimit: .random(in: 1...100)),
                                         monitor: .init(protonAddress: .random(), aliases: .random()),
                                         pendingInvites: 1,
                                         waitingNewUserInvites: 1,
                                         minVersionUpgrade: nil,
                                         userData: UserAliasSyncData.default))
            }

            localAccessDatasource.stubbedGetAccessResult = access
        }

        userSettingsRepository.closureGetSettings = { [weak self] in
            guard let self else { return }
            let userId = userSettingsRepository.invokedGetSettingsParameters?.0 ?? ""
            let settings: UserSettings = switch userId {
            case userId2:
                // Paid user with telemetry turned off
                    .init(telemetry: false,
                          highSecurity: .default,
                          password: .init(mode: .singlePassword),
                          twoFactor: .init(type: .disabled))

            case userId3:
                // Business user with telemetry turned on
                    .init(telemetry: true,
                          highSecurity: .default,
                          password: .init(mode: .singlePassword),
                          twoFactor: .init(type: .disabled))

            default:
                // Free user with telemetry turned on
                    .init(telemetry: true,
                          highSecurity: .default,
                          password: .init(mode: .singlePassword),
                          twoFactor: .init(type: .disabled))
            }

            userSettingsRepository.stubbedGetSettingsResult = settings
        }

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(-1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)
        // Send only 1 event at a time to test if the while loop inside TelemetryEventRepository
        // works correctly when dealing with a large number of events
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: userSettingsRepository,
                                       localAccessDatasource: localAccessDatasource,
                                       itemReadEventRepository: itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager,
                                       batchSize: 1)

        // When
        try await sut.addNewEvent(userId: userId1, type: .create(.login))
        try await sut.addNewEvent(userId: userId1, type: .read(.alias))
        try await sut.addNewEvent(userId: userId2, type: .update(.note))
        try await sut.addNewEvent(userId: userId3, type: .delete(.login))

        let sendResult = try await sut.sendAllEventsIfApplicable()
        let events1 = try await localDatasource.getOldestEvents(count: 100, userId: userId1)
        let events2 = try await localDatasource.getOldestEvents(count: 100, userId: userId2)
        let events3 = try await localDatasource.getOldestEvents(count: 100, userId: userId3)

        let threshold = await telemetryScheduler.getThreshold()
        let newThreshold = try XCTUnwrap(threshold)
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenCurrentDate,
                                                         to: newThreshold)
        let differenceInHours = try XCTUnwrap(difference.hour)

        // Then
        XCTAssertEqual(sendResult, .allEventsSent(userIds: [userId3, userId1]))
        // No more events left in local db for all users
        XCTAssertTrue(events1.isEmpty)
        XCTAssertTrue(events2.isEmpty)
        XCTAssertTrue(events3.isEmpty)

        let minInterval = await telemetryScheduler.minIntervalInHours
        let maxInterval = await telemetryScheduler.maxIntervalInHours
        XCTAssertTrue(differenceInHours >= minInterval)
        XCTAssertTrue(differenceInHours <= maxInterval)

        XCTAssertEqual(itemReadEventRepository.invokedSendAllEventsCount, 1)
    }

    func testRemoveAllLocalEventsWhenThresholdIsReachedButTelemetryIsOff() async throws {
        // Given
        let user = UserData.random()
        let userId = user.user.ID

        let givenCurrentDate = Date.now
        var mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        userManager.stubbedGetAllUsersResult = [user]
        userSettingsRepository.stubbedGetSettingsResult = .init(telemetry: false,
                                                                highSecurity: .default,
                                                                password: .init(mode: .singlePassword),
                                                                twoFactor: .init(type: .disabled))

        let freeAccess = Access(plan: .init(type: "free",
                                            internalName: .random(),
                                            displayName: .random(),
                                            hideUpgrade: false,
                                            manageAlias: false,
                                            trialEnd: .random(in: 1...100),
                                            vaultLimit: .random(in: 1...100),
                                            aliasLimit: .random(in: 1...100),
                                            totpLimit: .random(in: 1...100)),
                                monitor: .init(protonAddress: .random(), aliases: .random()),
                                pendingInvites: 1,
                                waitingNewUserInvites: 1,
                                minVersionUpgrade: nil, 
                                userData: UserAliasSyncData.default)
        localAccessDatasource.stubbedGetAccessResult = .init(userId: userId, access: freeAccess)

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(-1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)
        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: userSettingsRepository,
                                       localAccessDatasource: localAccessDatasource,
                                       itemReadEventRepository: itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager)

        // When
        try await sut.addNewEvent(userId: userId, type: .create(.login))
        try await sut.addNewEvent(userId: userId, type: .read(.alias))
        try await sut.addNewEvent(userId: userId, type: .update(.note))
        try await sut.addNewEvent(userId: userId, type: .delete(.login))

        let sendResult = try await sut.sendAllEventsIfApplicable()
        let events = try await localDatasource.getOldestEvents(count: 100, userId: userId)
        let threshold = await telemetryScheduler.getThreshold()
        let newThreshold = try XCTUnwrap(threshold)
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenCurrentDate,
                                                         to: newThreshold)
        let differenceInHours = try XCTUnwrap(difference.hour)

        // Then
        XCTAssertEqual(sendResult, .allEventsSent(userIds: []))
        XCTAssertTrue(events.isEmpty) // No more events left in local db
        let minInterval = await telemetryScheduler.minIntervalInHours
        let maxInterval = await telemetryScheduler.maxIntervalInHours
        XCTAssertTrue(differenceInHours >= minInterval)
        XCTAssertTrue(differenceInHours <= maxInterval)
        XCTAssertFalse(itemReadEventRepository.invokedSendAllEventsfunction)
    }

    func testSendItemReadEventsForB2BWhenThresholdIsReachedButTelemetryIsOff() async throws {
        // Given
        let user = UserData.random()
        let userId = user.user.ID

        let givenCurrentDate = Date.now
        var mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(-1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)

        userManager.stubbedGetAllUsersResult = [user]
        userSettingsRepository.stubbedGetSettingsResult = .init(telemetry: false,
                                                                highSecurity: .default,
                                                                password: .init(mode: .singlePassword),
                                                                twoFactor: .init(type: .disabled))

        let businessAccess = Access(plan: .init(type: "business",
                                                internalName: .random(),
                                                displayName: .random(),
                                                hideUpgrade: false,
                                                manageAlias: false,
                                                trialEnd: .random(in: 1...100),
                                                vaultLimit: .random(in: 1...100),
                                                aliasLimit: .random(in: 1...100),
                                                totpLimit: .random(in: 1...100)),
                                    monitor: .init(protonAddress: .random(), aliases: .random()),
                                    pendingInvites: 1,
                                    waitingNewUserInvites: 1,
                                    minVersionUpgrade: nil, 
                                    userData: UserAliasSyncData.default)
        localAccessDatasource.stubbedGetAccessResult = .init(userId: userId, access: businessAccess)

        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: userSettingsRepository,
                                       localAccessDatasource: localAccessDatasource,
                                       itemReadEventRepository: itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager)

        // When
        let sendResult = try await sut.sendAllEventsIfApplicable()

        // Then
        XCTAssertEqual(sendResult, .allEventsSent(userIds: []))
        XCTAssertTrue(itemReadEventRepository.invokedSendAllEventsfunction)
    }

    func testSendItemReadEventsForB2BWhenThresholdIsReached() async throws {
        // Given
        let user = UserData.random()
        let userId = user.user.ID

        let givenCurrentDate = Date.now
        var mockedCurrentDateProvider = MockedCurrentDateProvider()
        mockedCurrentDateProvider.currentDate = givenCurrentDate

        thresholdProvider.telemetryThreshold = givenCurrentDate.addingTimeInterval(-1).timeIntervalSince1970
        let telemetryScheduler = TelemetryScheduler(currentDateProvider: mockedCurrentDateProvider,
                                                    thresholdProvider: thresholdProvider)

        userManager.stubbedGetAllUsersResult = [user]
        userSettingsRepository.stubbedGetSettingsResult = .init(telemetry: true,
                                                                highSecurity: .default,
                                                                password: .init(mode: .singlePassword),
                                                                twoFactor: .init(type: .disabled))

        let businessAccess = Access(plan: .init(type: "business",
                                                internalName: .random(),
                                                displayName: .random(),
                                                hideUpgrade: false,
                                                manageAlias: false,
                                                trialEnd: .random(in: 1...100),
                                                vaultLimit: .random(in: 1...100),
                                                aliasLimit: .random(in: 1...100),
                                                totpLimit: .random(in: 1...100)),
                                    monitor: .init(protonAddress: .random(), aliases: .random()),
                                    pendingInvites: 1,
                                    waitingNewUserInvites: 1,
                                    minVersionUpgrade: nil, 
                                    userData: UserAliasSyncData.default)
        localAccessDatasource.stubbedGetAccessResult = .init(userId: userId, access: businessAccess)

        sut = TelemetryEventRepository(localDatasource: localDatasource,
                                       remoteDatasource: MockedRemoteDatasource(),
                                       userSettingsRepository: userSettingsRepository,
                                       localAccessDatasource: localAccessDatasource,
                                       itemReadEventRepository:
                                        itemReadEventRepository,
                                       logManager: LogManager.dummyLogManager(),
                                       scheduler: telemetryScheduler,
                                       userManager: userManager,
                                       batchSize: 1)

        // When
        let sendResult = try await sut.sendAllEventsIfApplicable()

        // Then
        XCTAssertEqual(sendResult, .allEventsSent(userIds: [userId]))
        XCTAssertTrue(itemReadEventRepository.invokedSendAllEventsfunction)
    }
}
