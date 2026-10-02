//
// PreferencesManagerTests.swift
// Proton Pass - Created on 29/03/2024.
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
//

@testable import Client
import ClientMocks
import Combine
import CoreMocks
import CryptoKit
import Entities
import Testing

@Suite(.tags(.manager))
struct PreferencesManagerTests {
    private let userManager = UserManagerProtocolMock()
    private let appPreferencesDatasource: LocalAppPreferencesDatasourceProtocolMock
    private let sharedPreferencesDatasource: any LocalSharedPreferencesDatasourceProtocol
    private let userPreferencesDatasource: any LocalUserPreferencesDatasourceProtocol
    private let sut: any PreferencesManagerProtocol

    init() {
        userManager.stubbedGetActiveUserDataResult = .random()

        let keychainMockProvider = KeychainProtocolMockProvider()
        keychainMockProvider.setUp()

        let symmetricKeyProviderMockFactory = SymmetricKeyProviderMockFactory()
        symmetricKeyProviderMockFactory.setUp()

        let appPreferencesDatasource = LocalAppPreferencesDatasourceProtocolMock()
        appPreferencesDatasource.closureUpsertPreferences = { [weak appPreferencesDatasource] in
            guard let appPreferencesDatasource else { return }
            appPreferencesDatasource.stubbedGetPreferencesResult =
                appPreferencesDatasource.invokedUpsertPreferencesParameters?.preferences
        }
        appPreferencesDatasource.closureRemovePreferences = { [weak appPreferencesDatasource] in
            guard let appPreferencesDatasource else { return }
            appPreferencesDatasource.stubbedGetPreferencesResult = nil
        }
        self.appPreferencesDatasource = appPreferencesDatasource

        sharedPreferencesDatasource =
            LocalSharedPreferencesDatasource(symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                                             keychain: keychainMockProvider.getKeychain())

        userPreferencesDatasource =
            LocalUserPreferencesDatasource(symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                                           databaseService: DatabaseService(inMemory: true))

        sut = PreferencesManager(userManager: userManager,
                                 appPreferencesDatasource: appPreferencesDatasource,
                                 sharedPreferencesDatasource: sharedPreferencesDatasource,
                                 userPreferencesDatasource: userPreferencesDatasource,
                                 logManager: LogManagerProtocolMock())
    }
}

// MARK: - App preferences

extension PreferencesManagerTests {
    @Test func `setting up creates default app preferences`() async throws {
        try await sut.setUp()
        #expect(sut.appPreferences.value == .default)
    }

    @Test func `updating app preferences emits the new value`() async throws {
        try await sut.setUp()
        let newValue = Int.random(in: 1...100)
        var cancellables = Set<AnyCancellable>()
        var receivedValues = [Int]()
        sut.appPreferencesUpdates
            .filter(\.createdItemsCount)
            .sink { receivedValues.append($0) }
            .store(in: &cancellables)

        try await sut.updateAppPreferences(\.createdItemsCount, value: newValue)

        #expect(sut.appPreferences.value?.createdItemsCount == newValue)
        #expect(receivedValues == [newValue])
    }

    @Test func `removing app preferences deletes them from the datasource`() async throws {
        try await sut.setUp()
        await sut.removeAppPreferences()
        let preferences = try appPreferencesDatasource.getPreferences()
        #expect(preferences == nil)
    }
}

// MARK: - Shared preferences

extension PreferencesManagerTests {
    @Test func `setting up creates default shared preferences`() async throws {
        try await sut.setUp()
        #expect(sut.sharedPreferences.value == SharedPreferences.default)
    }

    @Test func `updating shared preferences emits the new values including nil`() async throws {
        try await sut.setUp()
        var cancellables = Set<AnyCancellable>()

        let newAppLockTime = try #require(AppLockTime.random())
        var receivedAppLockTimes = [AppLockTime]()
        sut.sharedPreferencesUpdates
            .filter(\.appLockTime)
            .sink { receivedAppLockTimes.append($0) }
            .store(in: &cancellables)

        // Explicitly test nil to see if we can receive events for nullable values
        let newPinCode: String? = nil
        var receivedPinCodes = [String?]()
        sut.sharedPreferencesUpdates
            .filter(\.pinCode)
            .sink { receivedPinCodes.append($0) }
            .store(in: &cancellables)

        try await sut.updateSharedPreferences(\.appLockTime, value: newAppLockTime)
        try await sut.updateSharedPreferences(\.pinCode, value: newPinCode)

        #expect(sut.sharedPreferences.value?.appLockTime == newAppLockTime)
        #expect(sut.sharedPreferences.value?.pinCode == newPinCode)
        #expect(receivedAppLockTimes == [newAppLockTime])
        #expect(receivedPinCodes == [newPinCode])
    }

    @Test func `removing shared preferences deletes them from the datasource`() async throws {
        try await sut.setUp()
        try await sut.removeSharedPreferences()
        let preferences = try await sharedPreferencesDatasource.getPreferences()
        #expect(preferences == nil)
    }
}

// MARK: - User's preferences

extension PreferencesManagerTests {
    @Test func `setting up creates default user preferences`() async throws {
        try await sut.setUp()
        #expect(sut.userPreferences.value == UserPreferences.default)
    }

    @Test func `updating user preferences emits the new value`() async throws {
        try await sut.setUp()
        let newValue = try #require(SpotlightSearchableContent.random())
        var cancellables = Set<AnyCancellable>()
        var receivedValues = [SpotlightSearchableContent]()
        sut.userPreferencesUpdates
            .filter(\.spotlightSearchableContent)
            .sink { receivedValues.append($0) }
            .store(in: &cancellables)

        try await sut.updateUserPreferences(\.spotlightSearchableContent, value: newValue)

        #expect(sut.userPreferences.value?.spotlightSearchableContent == newValue)
        #expect(receivedValues == [newValue])
    }

    @Test func `removing user preferences deletes them and clears the current value`() async throws {
        try await sut.setUp()
        try await sut.removeUserPreferences()
        if let userId = try? await userManager.getActiveUserId() {
            let preferences = try await userPreferencesDatasource.getPreferences(for: userId)
            #expect(preferences == nil)
        }
        #expect(sut.userPreferences.value == nil)
    }
}

extension PreferencesManagerTests {
    @Test func `filtering by several key paths emits once per matching update`() async throws {
        try await sut.setUp()
        var cancellables = Set<AnyCancellable>()
        var onboardedCount = 0
        var thresholdCount = 0
        var onboardedOrThresholdCount = 0
        var anyOfThreeCount = 0

        sut.appPreferencesUpdates
            .filter([\.onboarded])
            .sink { _ in onboardedCount += 1 }
            .store(in: &cancellables)

        sut.appPreferencesUpdates
            .filter([\.telemetryThreshold])
            .sink { _ in thresholdCount += 1 }
            .store(in: &cancellables)

        sut.appPreferencesUpdates
            .filter([\.onboarded, \.telemetryThreshold])
            .sink { _ in onboardedOrThresholdCount += 1 }
            .store(in: &cancellables)

        sut.appPreferencesUpdates
            .filter([\.onboarded, \.telemetryThreshold, \.createdItemsCount])
            .sink { _ in anyOfThreeCount += 1 }
            .store(in: &cancellables)

        try await sut.updateAppPreferences(\.onboarded, value: .random())
        try await sut.updateAppPreferences(\.telemetryThreshold, value: .random(in: 1...10))
        try await sut.updateAppPreferences(\.createdItemsCount, value: .random(in: 1...10))

        #expect(onboardedCount == 1)
        #expect(thresholdCount == 1)
        #expect(onboardedOrThresholdCount == 2)
        #expect(anyOfThreeCount == 3)
    }
}
