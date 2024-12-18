//
// SendUserMonitoringStatsTests.swift
// Proton Pass - Created on 17/12/2024.
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

@testable import UseCases
import Client
import ClientMocks
import Entities
import EntitiesMocks
import Foundation
import ProtonCoreLogin
import Testing

@Suite(.serialized, .tags(.monitor))
struct SendUserMonitoringStatsTests {
    // Mocks
    private let passMonitorRepository: PassMonitorRepositoryProtocolMock
    private let accessRepository: AccessRepositoryProtocolMock
    private let userManager: UserManagerProtocolMock
    private let userDefaults: UserDefaults
    private let sut: SendUserMonitoringStatsUseCase
    private let lastSavedTimestampKey = "lastSentStatsTimestamp"

    let user = UserData(credential: .init(sessionID: "test_session_id",
                                          accessToken: "test_access_token",
                                          refreshToken: "test_refresh_token",
                                          userName: "test_user_name",
                                          userID: "test_user_id",
                                          privateKey: nil,
                                          passwordKeySalt: nil),
                        user: .init(ID: "test_user_id",
                                    name: nil,
                                    usedSpace: 0,
                                    usedBaseSpace: 0,
                                    usedDriveSpace: 0,
                                    currency: "",
                                    credit: 0,
                                    maxSpace: 0,
                                    maxBaseSpace: 0,
                                    maxDriveSpace: 0,
                                    maxUpload: 0,
                                    role: 0,
                                    private: 0,
                                    subscribed: [],
                                    services: 0,
                                    delinquent: 0,
                                    orgPrivateKey: nil,
                                    email: nil,
                                    displayName: nil,
                                    keys: []),
                        salts: [],
                        passphrases: [:],
                        addresses: [],
                        scopes: ["test_scope"])

    init() {
        // Initialize mocks
        passMonitorRepository = PassMonitorRepositoryProtocolMock()
        accessRepository = AccessRepositoryProtocolMock()
        userManager = UserManagerProtocolMock()
        userManager.stubbedGetActiveUserDataResult = user
        userDefaults = UserDefaults(suiteName: "testSuite")!
        userDefaults.removePersistentDomain(forName: "testSuite")

        sut = SendUserMonitoringStats(passMonitorRepository: passMonitorRepository,
                                      accessRepository: accessRepository,
                                      userManager: userManager,
                                      storage: userDefaults)
    }

    @Test("Should not send stats if less than 24 hours since last sent")
    func shouldNotSendStatsAsTimeNotValid() async throws {
        // Arrange: Store a recent timestamp
        let recentTime = Date().addingTimeInterval(-60 * 60 * 2) // 2 hours ago
        userDefaults.set(recentTime, forKey: lastSavedTimestampKey)

        // Act
        try await sut()

        #expect(passMonitorRepository.invokedSendUserMonitorStatsfunction == false)
    }

    @Test("Should not send stats as more than 24 hours has passed since last sent but plan is not business")
    func shouldSendStatsAsPlanNotValid() async throws {
        // Arrange: Store a timestamp 25 hours ago
        let oldTime = Date().addingTimeInterval(-60 * 60 * 25) // 25 hours ago
        userDefaults.set(oldTime, forKey: lastSavedTimestampKey)
        accessRepository.stubbedGetAccessResult = UserAccess.mock()
        // Act
        try await sut()

        #expect(passMonitorRepository.invokedSendUserMonitorStatsfunction == false)
    }

    @Test("Should send stats as more than 24 hours has passed since last sent and plan is business")
    func shouldSendStats() async throws {
        // Arrange: Store a timestamp 25 hours ago
        let oldTime = Date().addingTimeInterval(-60 * 60 * 25) // 25 hours ago
        userDefaults.set(oldTime, forKey: lastSavedTimestampKey)
        accessRepository.stubbedGetAccessResult = UserAccess.mock(access: .mock(plan: .mockBusinessPlan))
        // Act
        try await sut()

        #expect(passMonitorRepository.invokedSendUserMonitorStatsfunction == true)
    }

    @Test("Should send as stats never sent and plan is business")
    func shouldSendStatsAsNoTimestamp() async throws {
        userDefaults.removeObject(forKey: lastSavedTimestampKey)

        passMonitorRepository.invokedSendUserMonitorStatsfunction = false

        accessRepository.stubbedGetAccessResult = UserAccess.mock(access: .mock(plan: .mockBusinessPlan))
        // Act
        try await sut()

        #expect(passMonitorRepository.invokedSendUserMonitorStatsfunction == true)
    }

    @Test("Should update timestamp")
    func shouldUpdateTimestamp() async throws {
        // Arrange: 25 hours have passed
        let oldTime = Date().addingTimeInterval(-60 * 60 * 25) // 25 hours ago
        userDefaults.set(oldTime, forKey: lastSavedTimestampKey)
        passMonitorRepository.invokedSendUserMonitorStatsfunction = false

        accessRepository.stubbedGetAccessResult = UserAccess.mock(access: .mock(plan: .mockBusinessPlan))
        // Act
        try await sut()

        let savedTimestamp = userDefaults.object(forKey: lastSavedTimestampKey) as? Date

        #expect(savedTimestamp != oldTime)
        #expect(passMonitorRepository.invokedSendUserMonitorStatsfunction == true)
    }
}
