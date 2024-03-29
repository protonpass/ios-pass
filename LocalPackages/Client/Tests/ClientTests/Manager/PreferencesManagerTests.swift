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
        sut = PreferencesManager(symmetricKeyProvider: symmetricKeyProvider,
                                 databaseService: DatabaseService(inMemory: true))
    }

    override func tearDown() {
        symmetricKeyProvider = nil
        sut = nil
        cancellable = nil
        super.tearDown()
    }
}

extension PreferencesManagerTest {
    func testCreateAndThenReceiveCreationEvent() async throws {
        // Given
        let userId = String.random()
        let givenPref = UserPreferences.random()
        let expectation = XCTestExpectation(description: "Should receive creation event")
        cancellable = sut.userPreferencesUpdates
            .sink { event in
                if case .creation = event {
                    expectation.fulfill()
                }
            }

        // When
        try await sut.create(preferences: givenPref, for: userId)

        // Then
        let pref = try await XCTUnwrapAsync(await sut.getPreferences(for: userId))
        XCTAssertEqual(pref, givenPref)
        await fulfillment(of: [expectation])
    }
}
