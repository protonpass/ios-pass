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
import CoreMocks
import Combine
import CryptoKit
import Entities
import XCTest

final class PreferencesManagerTest: XCTestCase {
    var userManager: UserManagerProtocolMock!
    var keychainMockProvider: KeychainProtocolMockProvider!
    var symmetricKeyProviderMockFactory: SymmetricKeyProviderMockFactory!
    var appPreferencesDatasource: LocalAppPreferencesDatasourceProtocolMock!
    var lastAppPreferences: AppPreferences!
    var sharedPreferencesDatasource: LocalSharedPreferencesDatasourceProtocol!
    var userPreferencesDatasource: LocalUserPreferencesDatasourceProtocol!
    var sut: PreferencesManagerProtocol!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        userManager = .init()
        userManager.stubbedGetActiveUserDataResult = .random()

        keychainMockProvider = .init()
        keychainMockProvider.setUp()

        symmetricKeyProviderMockFactory = .init()
        symmetricKeyProviderMockFactory.setUp()

        appPreferencesDatasource = .init()
        appPreferencesDatasource.stubbedGetPreferencesResult = lastAppPreferences
        appPreferencesDatasource.closureUpsertPreferences = {
            if let prefs = self.appPreferencesDatasource.invokedUpsertPreferencesParameters?.0 {
                self.lastAppPreferences = prefs
            }
        }
        appPreferencesDatasource.closureRemovePreferences = {
            self.lastAppPreferences = nil
        }

        sharedPreferencesDatasource =
        LocalSharedPreferencesDatasource(symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                                         keychain: keychainMockProvider.getKeychain())

        userPreferencesDatasource =
        LocalUserPreferencesDatasource(symmetricKeyProvider: symmetricKeyProviderMockFactory.getProvider(),
                                       databaseService: DatabaseService(inMemory: true))

        cancellables = .init()

        sut = PreferencesManager(userManager: userManager,
                                 appPreferencesDatasource: appPreferencesDatasource,
                                 sharedPreferencesDatasource: sharedPreferencesDatasource,
                                 userPreferencesDatasource: userPreferencesDatasource, 
                                 logManager: LogManagerProtocolMock())
    }

    override func tearDown() {
        keychainMockProvider = nil
        symmetricKeyProviderMockFactory = nil
        userPreferencesDatasource = nil
        sharedPreferencesDatasource = nil
        sut = nil
        cancellables = nil
        super.tearDown()
    }
}

// MARK: - App preferences
extension PreferencesManagerTest {
    func testCreateDefaultAppPreferences() async throws {
        try await sut.setUp()
        XCTAssertEqual(sut.appPreferences.value, .default)
    }

    func testReceiveEventWhenUpdatingAppPreferences() async throws {
        // Given
        try await sut.setUp()
        let expectation = expectation(description: "Should receive update event")
        let newValue = Int.random(in: 1...100)
        sut.appPreferencesUpdates
            .filter(\.createdItemsCount)
            .sink { value in
                if value == newValue {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        try await sut.updateAppPreferences(\.createdItemsCount, value: newValue)

        // Then
        XCTAssertEqual(sut.appPreferences.value?.createdItemsCount, newValue)
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testRemoveAppPreferences() async throws {
        try await sut.setUp()
        await sut.removeAppPreferences()
        let preferences = try appPreferencesDatasource.getPreferences()
        XCTAssertNil(preferences)
    }
}

// MARK: - Shared preferences
extension PreferencesManagerTest {
    func testCreateDefaultSharedPreferences() async throws {
        try await sut.setUp()
        XCTAssertEqual(sut.sharedPreferences.value, SharedPreferences.default)
    }

    func testReceiveEventWhenUpdatingSharedPreferences() async throws {
        // Given
        try await sut.setUp()

        let expectationAppLockTime = expectation(description: "Should receive update event")
        let newAppLockTime = try XCTUnwrap(AppLockTime.random())
        sut.sharedPreferencesUpdates
            .filter(\.appLockTime)
            .sink { value in
                if value == newAppLockTime {
                    expectationAppLockTime.fulfill()
                }
            }
            .store(in: &cancellables)

        let expectationPinCode = expectation(description: "Should receive update event")
        // Explicitly test nil to see if we can receive events for nullable values
        let newPinCode: String? = nil
        sut.sharedPreferencesUpdates
            .filter(\.pinCode)
            .sink { value in
                if value == newPinCode {
                    expectationPinCode.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        try await sut.updateSharedPreferences(\.appLockTime, value: newAppLockTime)
        try await sut.updateSharedPreferences(\.pinCode, value: newPinCode)

        // Then
        XCTAssertEqual(sut.sharedPreferences.value?.appLockTime, newAppLockTime)
        XCTAssertEqual(sut.sharedPreferences.value?.pinCode, newPinCode)
        await fulfillment(of: [expectationAppLockTime, expectationPinCode], timeout: 1)
    }

    func testRemoveSharedPreferences() async throws {
        try await sut.setUp()
        try await sut.removeSharedPreferences()
        let preferences = try await sharedPreferencesDatasource.getPreferences()
        XCTAssertNil(preferences)
    }
}

// MARK: - User's preferences
extension PreferencesManagerTest {
    func testCreateDefaultUserPreferences() async throws {
        try await sut.setUp()
        XCTAssertEqual(sut.userPreferences.value, UserPreferences.default)
    }

    func testReceiveEventWhenUpdatingUserPreferences() async throws {
        // Given
        try await sut.setUp()
        let expectation = expectation(description: "Should receive update event")
        let newValue = try XCTUnwrap(SpotlightSearchableContent.random())
        sut.userPreferencesUpdates
            .filter(\.spotlightSearchableContent)
            .sink { value in
                if value == newValue {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        try await sut.updateUserPreferences(\.spotlightSearchableContent, value: newValue)

        // Then
        XCTAssertEqual(sut.userPreferences.value?.spotlightSearchableContent, newValue)
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testRemoveUserPreferences() async throws {
        try await sut.setUp()
        try await sut.removeUserPreferences()
        if let userId = try? await userManager.getActiveUserId() {
            let preferences = try await userPreferencesDatasource.getPreferences(for: userId)
            XCTAssertNil(preferences)
        }
        XCTAssertNil(sut.userPreferences.value)
    }
}

extension PreferencesManagerTest {
    func testFilterMultipleKeysPath() async throws {
        try await sut.setUp()
        let expectation1 = expectation(description: "Should receive 1 update event")
        expectation1.expectedFulfillmentCount = 1

        let expectation2 = expectation(description: "Should receive 1 update event")
        expectation2.expectedFulfillmentCount = 1

        let expectation3 = expectation(description: "Should receive 2 update events")
        expectation3.expectedFulfillmentCount = 2

        let expectation4 = expectation(description: "Should receive 3 update events")
        expectation4.expectedFulfillmentCount = 3

        sut.appPreferencesUpdates
            .filter([\.onboarded])
            .sink { _ in
                expectation1.fulfill()
            }
            .store(in: &cancellables)

        sut.appPreferencesUpdates
            .filter([\.telemetryThreshold])
            .sink { _ in
                expectation2.fulfill()
            }
            .store(in: &cancellables)

        sut.appPreferencesUpdates
            .filter([\.onboarded, \.telemetryThreshold])
            .sink { _ in
                expectation3.fulfill()
            }
            .store(in: &cancellables)

        sut.appPreferencesUpdates
            .filter([\.onboarded, \.telemetryThreshold, \.createdItemsCount])
            .sink { _ in
                expectation4.fulfill()
            }
            .store(in: &cancellables)

        try await sut.updateAppPreferences(\.onboarded, value: .random())
        try await sut.updateAppPreferences(\.telemetryThreshold, value: .random(in: 1...10))
        try await sut.updateAppPreferences(\.createdItemsCount, value: .random(in: 1...10))
        await fulfillment(of: [expectation1, expectation2, expectation3, expectation4],
                          timeout: 1)
    }
}
