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
import Combine
import CryptoKit
import Entities
import XCTest
import ClientMocks

final class PreferencesManagerTest: XCTestCase {
    let symmetricKey = SymmetricKey.random()
    var symmetricKeyProvider: SymmetricKeyProviderMock!
    var sut: PreferencesManagerProtocol!
    var cancellable: AnyCancellable!

    override func setUp() {
        super.setUp()
        symmetricKeyProvider = SymmetricKeyProviderMock()
        symmetricKeyProvider.stubbedGetSymmetricKeyResult = symmetricKey
    }

    override func tearDown() {
        symmetricKeyProvider = nil
        sut = nil
        cancellable = nil
        super.tearDown()
    }

    func initSut() async throws {
        sut = try await PreferencesManager(symmetricKeyProvider: symmetricKeyProvider,
                                            databaseService: DatabaseService(inMemory: true),
                                            userId: .random())
    }
}

extension PreferencesManagerTest {
    func testCreateDefaultUserPreferences() async throws {
        try await initSut()
        XCTAssertEqual(sut.userPreferences.value, UserPreferences.default)
    }

    func testReceiveEventWhenUpdatingUserPreferences() async throws {
        // Given
        try await initSut()
        let expectation = XCTestExpectation(description: "Should receive update event")
        let givenPrefs = sut.userPreferences.value
        let newValue = !givenPrefs.quickTypeBar
        cancellable = sut.userPreferencesUpdates
            .filterUserPreferencesUpdate(\.quickTypeBar)
            .sink { value in
                if value == newValue {
                    expectation.fulfill()
                }
            }

        // When
        try await sut.updateUserPreferences(\.quickTypeBar, value: newValue)

        // Then
        XCTAssertEqual(sut.userPreferences.value.quickTypeBar, newValue)
        await fulfillment(of: [expectation], timeout: 1)
    }
}
