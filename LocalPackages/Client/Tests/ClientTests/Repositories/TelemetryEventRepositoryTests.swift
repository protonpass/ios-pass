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
import Foundation
import ProtonCoreLogin
import ProtonCoreNetworking
import Testing

private final class MockedRemoteDatasource: RemoteTelemetryEventDatasourceProtocol {
    func send(userId: String, events: [Client.EventInfo]) async throws {}

    func send(events: [EventInfo]) async throws {}
}

private struct MockedCurrentDateProvider: CurrentDateProviderProtocol {
    var currentDate = Date.now
    func getCurrentDate() -> Date { currentDate }
}

@Suite(.tags(.repository))
struct TelemetryEventRepositoryTests {
    let localDatasource: LocalTelemetryEventDatasourceProtocol
    let localAccessDatasource: LocalAccessDatasourceProtocolMock
    let thresholdProvider: TelemetryThresholdProviderMock
    let userSettingsRepository: UserSettingsRepositoryProtocolMock
    let userManager: UserManagerProtocolMock
    let itemReadEventRepository: ItemReadEventRepositoryProtocolMock
    var sut: TelemetryEventRepositoryProtocol!

    init() {
        localDatasource = LocalTelemetryEventDatasource(databaseService: DatabaseService(inMemory: true))
        localAccessDatasource = .init()
        thresholdProvider = .init()
        userSettingsRepository = .init()
        userManager = .init()
        userManager.stubbedGetActiveUserDataResult = UserData.preview
        itemReadEventRepository = .init()
    }
}

extension TelemetryEventRepositoryTests {
    @Test("Add new events")
    mutating func testAddNewEvents() async throws {
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
        #expect(events1.count == 2)
        #expect(events1[0].type == .create(.login))
        #expect(events1[1].type == .read(.alias))

        #expect(events2.count == 1)
        #expect(events2[0].type == .update(.note))

        #expect(events3.count == 1)
        #expect(events3[0].type == .delete(.login))
    }

    @Test("Auto generate threshold when current threshold is nil")
    mutating func testAutoGenerateThresholdWhenCurrentThresholdIsNil() async throws {
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
        #expect(threshold == nil)

        // When
        let sendResult = try await sut.sendAllEventsIfApplicable()

        // Then
        threshold = await sut.scheduler.getThreshold()
        #expect(threshold != nil)
        #expect(sendResult == .thresholdNotReached)
        #expect(!itemReadEventRepository.invokedSendAllEventsfunction)
    }

    @Test("Do not send event when threshold not reached")
    mutating func testDoNotSendEventWhenThresholdNotReached() async throws {
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
        #expect(sendResult == .thresholdNotReached)
        #expect(!itemReadEventRepository.invokedSendAllEventsfunction)
    }

    @Test("Send all events and random new threshold if threshold is reached")
    mutating func testSendAllEventsAndRandomNewThresholdIfThresholdIsReached() async throws {
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

        let nonMutatingSelf = self
        localAccessDatasource.closureGetAccess = {
            let userId = nonMutatingSelf.localAccessDatasource.invokedGetAccessParameters?.0 ?? ""
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
                                                     totpLimit: .random(in: 1...100),
                                                     storageAllowed: true,
                                                     storageUsed: .random(in: 1...100),
                                                     storageQuota: .random(in: 1...100)),
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
                                                     totpLimit: .random(in: 1...100),
                                                     storageAllowed: true,
                                                     storageUsed: .random(in: 1...100),
                                                     storageQuota: .random(in: 1...100)),
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
                                                     totpLimit: .random(in: 1...100),
                                                     storageAllowed: false,
                                                     storageUsed: .random(in: 1...100),
                                                     storageQuota: .random(in: 1...100)),
                                         monitor: .init(protonAddress: .random(), aliases: .random()),
                                         pendingInvites: 1,
                                         waitingNewUserInvites: 1,
                                         minVersionUpgrade: nil,
                                         userData: UserAliasSyncData.default))
            }

            nonMutatingSelf.localAccessDatasource.stubbedGetAccessResult = access
        }

        userSettingsRepository.closureGetSettings = {
            let userId = nonMutatingSelf.userSettingsRepository.invokedGetSettingsParameters?.0 ?? ""
            let settings: UserSettings = switch userId {
            case userId2:
                // Paid user with telemetry turned off
                    .init(telemetry: false,
                          highSecurity: .default,
                          password: .init(mode: .singlePassword),
                          twoFactor: .init(type: .disabled),
                          flags: .init(edmOptOut: .optedIn))

            case userId3:
                // Business user with telemetry turned on
                    .init(telemetry: true,
                          highSecurity: .default,
                          password: .init(mode: .singlePassword),
                          twoFactor: .init(type: .disabled),
                          flags: .init(edmOptOut: .optedIn))

            default:
                // Free user with telemetry turned on
                    .init(telemetry: true,
                          highSecurity: .default,
                          password: .init(mode: .singlePassword),
                          twoFactor: .init(type: .disabled),
                          flags: .init(edmOptOut: .optedIn))
            }

            nonMutatingSelf.userSettingsRepository.stubbedGetSettingsResult = settings
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
        let newThreshold = try #require(threshold)
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenCurrentDate,
                                                         to: newThreshold)
        let differenceInHours = try #require(difference.hour)

        // Then
        #expect(sendResult == .allEventsSent(userIds: [userId3, userId1]))
        // No more events left in local db for all users
        #expect(events1.isEmpty)
        #expect(events2.isEmpty)
        #expect(events3.isEmpty)

        let minInterval = await telemetryScheduler.minIntervalInHours
        let maxInterval = await telemetryScheduler.maxIntervalInHours
        #expect(differenceInHours >= minInterval)
        #expect(differenceInHours <= maxInterval)

        #expect(itemReadEventRepository.invokedSendAllEventsCount == 1)
    }

    @Test("Remove all local events when threshold is reached but telemetry is off")
    mutating func testRemoveAllLocalEventsWhenThresholdIsReachedButTelemetryIsOff() async throws {
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
                                                                twoFactor: .init(type: .disabled),
                                                                flags: .init(edmOptOut: .optedIn))

        let freeAccess = Access(plan: .init(type: "free",
                                            internalName: .random(),
                                            displayName: .random(),
                                            hideUpgrade: false,
                                            manageAlias: false,
                                            trialEnd: .random(in: 1...100),
                                            vaultLimit: .random(in: 1...100),
                                            aliasLimit: .random(in: 1...100),
                                            totpLimit: .random(in: 1...100),
                                            storageAllowed: false,
                                            storageUsed: .random(in: 1...100),
                                            storageQuota: .random(in: 1...100)),
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
        let newThreshold = try #require(threshold)
        let difference = Calendar.current.dateComponents([.hour],
                                                         from: givenCurrentDate,
                                                         to: newThreshold)
        let differenceInHours = try #require(difference.hour)

        // Then
        #expect(sendResult == .allEventsSent(userIds: []))
        #expect(events.isEmpty) // No more events left in local db
        let minInterval = await telemetryScheduler.minIntervalInHours
        let maxInterval = await telemetryScheduler.maxIntervalInHours
        #expect(differenceInHours >= minInterval)
        #expect(differenceInHours <= maxInterval)
        #expect(!itemReadEventRepository.invokedSendAllEventsfunction)
    }

    @Test("Send item read events for B2B when threshold is reached but telemetry is off")
    mutating func testSendItemReadEventsForB2BWhenThresholdIsReachedButTelemetryIsOff() async throws {
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
                                                                twoFactor: .init(type: .disabled),
                                                                flags: .init(edmOptOut: .optedIn))

        let businessAccess = Access(plan: .init(type: "business",
                                                internalName: .random(),
                                                displayName: .random(),
                                                hideUpgrade: false,
                                                manageAlias: false,
                                                trialEnd: .random(in: 1...100),
                                                vaultLimit: .random(in: 1...100),
                                                aliasLimit: .random(in: 1...100),
                                                totpLimit: .random(in: 1...100),
                                                storageAllowed: true,
                                                storageUsed: .random(in: 1...100),
                                                storageQuota: .random(in: 1...100)),
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
        #expect(sendResult == .allEventsSent(userIds: []))
        #expect(itemReadEventRepository.invokedSendAllEventsfunction)
    }

    @Test("Send item read events for B2B when threshod is reached")
    mutating func testSendItemReadEventsForB2BWhenThresholdIsReached() async throws {
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
                                                                twoFactor: .init(type: .disabled),
                                                                flags: .init(edmOptOut: .optedIn))

        let businessAccess = Access(plan: .init(type: "business",
                                                internalName: .random(),
                                                displayName: .random(),
                                                hideUpgrade: false,
                                                manageAlias: false,
                                                trialEnd: .random(in: 1...100),
                                                vaultLimit: .random(in: 1...100),
                                                aliasLimit: .random(in: 1...100),
                                                totpLimit: .random(in: 1...100),
                                                storageAllowed: true,
                                                storageUsed: .random(in: 1...100),
                                                storageQuota: .random(in: 1...100)),
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
        #expect(sendResult == .allEventsSent(userIds: [userId]))
        #expect(itemReadEventRepository.invokedSendAllEventsfunction)
    }
}
