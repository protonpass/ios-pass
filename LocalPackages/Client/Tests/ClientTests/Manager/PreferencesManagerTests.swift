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
import CoreMocks
import Combine
import CryptoKit
import Entities
import XCTest
import ClientMocks

final class PreferencesManagerTest: XCTestCase {
    var keychainMockProvider: KeychainProtocolMockProvider!
    var symmetricKeyMockProvider: SymmetricKeyProviderMockProvider!
    var appPreferencesDatasource: LocalAppPreferencesDatasourceProtocol!
    var sharedPreferencesDatasource: LocalSharedPreferencesDatasourceProtocol!
    var userPreferencesDatasource: LocalUserPreferencesDatasourceProtocol!
    var userId: String!
    var sut: PreferencesManager!
    var cancellable: AnyCancellable!

    override func setUp() {
        super.setUp()
        keychainMockProvider = .init()
        keychainMockProvider.setUp()

        symmetricKeyMockProvider = .init()
        symmetricKeyMockProvider.setUp()

        appPreferencesDatasource = LocalAppPreferencesDatasource(userDefault: .standard)

        sharedPreferencesDatasource =
        LocalSharedPreferencesDatasource(symmetricKeyProvider: symmetricKeyMockProvider.getProvider(),
                                         keychain: keychainMockProvider.getKeychain())

        userPreferencesDatasource =
        LocalUserPreferencesDatasource(symmetricKeyProvider: symmetricKeyMockProvider.getProvider(),
                                       databaseService: DatabaseService(inMemory: true))

        userId = .random()
        sut = PreferencesManager(appPreferencesDatasource: appPreferencesDatasource,
                                 sharedPreferencesDatasource: sharedPreferencesDatasource, 
                                 userPreferencesDatasource: userPreferencesDatasource,
                                 userId: userId)
    }

    override func tearDown() {
        keychainMockProvider = nil
        symmetricKeyMockProvider = nil
        userPreferencesDatasource = nil
        sharedPreferencesDatasource = nil
        userId = nil
        sut = nil
        cancellable = nil
        super.tearDown()
    }
}

// MARK: - App preferences
extension PreferencesManagerTest {
    func testCreateDefaultAppPreferences() async throws {
        try await sut.setUp()
        XCTAssertEqual(sut.appPreferences.value, AppPreferences.default)
    }

    func testReceiveEventWhenUpdatingAppPreferences() async throws {
        // Given
        try await sut.setUp()
        let expectation = XCTestExpectation(description: "Should receive update event")
        let newValue = Int.random(in: 1...100)
        cancellable = sut.appPreferencesUpdates
            .filter(\.createdItemsCount)
            .sink { value in
                if value == newValue {
                    expectation.fulfill()
                }
            }

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
        let expectation = XCTestExpectation(description: "Should receive update event")
        let newValue = try XCTUnwrap(AppLockTime.random())
        cancellable = sut.sharedPreferencesUpdates
            .filter(\.appLockTime)
            .sink { value in
                if value == newValue {
                    expectation.fulfill()
                }
            }

        // When
        try await sut.updateSharedPreferences(\.appLockTime, value: newValue)

        // Then
        XCTAssertEqual(sut.sharedPreferences.value?.appLockTime, newValue)
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testRemoveSharedPreferences() async throws {
        try await sut.setUp()
        try await sut.removeSharedPreferences()
        let preferences = try sharedPreferencesDatasource.getPreferences()
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
        let expectation = XCTestExpectation(description: "Should receive update event")
        let newValue = try XCTUnwrap(SpotlightSearchableContent.random())
        cancellable = sut.userPreferencesUpdates
            .filter(\.spotlightSearchableContent)
            .sink { value in
                if value == newValue {
                    expectation.fulfill()
                }
            }

        // When
        try await sut.updateUserPreferences(\.spotlightSearchableContent, value: newValue)

        // Then
        XCTAssertEqual(sut.userPreferences.value?.spotlightSearchableContent, newValue)
        await fulfillment(of: [expectation], timeout: 1)
    }

    func testRemoveUserPreferences() async throws {
        try await sut.setUp()
        try await sut.removeUserPreferences()
        let preferences = try await userPreferencesDatasource.getPreferences(for: userId)
        XCTAssertNil(preferences)
    }
}
