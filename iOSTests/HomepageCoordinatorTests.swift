//
// HomepageCoordinatorTests.swift
// Proton Pass - Created on 15/04/2023.
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

import Client
import Core
@testable import Proton_Pass
import ProtonCore_Services
import XCTest

extension PMAPIService {
    static func dummyService() -> APIService {
        PMAPIService.createAPIServiceWithoutSession(environment: .black,
                                                    challengeParametersProvider: .empty)
    }
}

final class HomepageCoordinatorTests: XCTestCase {
    var sut: HomepageCoordinator!
    var preferences: Preferences!

    override func setUp() {
        super.setUp()
        let logManager = LogManager(module: .hostApp)
        let preferences = Preferences()
        self.preferences = preferences
        sut = .init(apiService: PMAPIService.dummyService(),
                    container: .Builder.build(name: kProtonPassContainerName,
                                              inMemory: true),
                    credentialManager: CredentialManager(logManager: logManager),
                    logManager: logManager,
                    manualLogIn: false,
                    preferences: preferences,
                    primaryPlan: nil,
                    symmetricKey: .init(data: Data.random()),
                    userData: .preview)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension HomepageCoordinatorTests {
    func testOnboardWhenNotForcedButNotOnboarded() {
        // Given
        preferences.onboarded = false

        // When
        let isOnboardShown = sut.onboardIfNecessary(forced: false)

        // Then
        XCTAssertTrue(isOnboardShown)
    }

    func testNotOnboardWhenNotForcedAndOnboarded() {
        // Given
        preferences.onboarded = true

        // When
        let isOnboardShown = sut.onboardIfNecessary(forced: false)

        // Then
        XCTAssertFalse(isOnboardShown)
    }

    func testOnboardWhenForcedButNotOnboarded() {
        // Given
        preferences.onboarded = true

        // When
        let isOnboardShown = sut.onboardIfNecessary(forced: true)

        // Then
        XCTAssertTrue(isOnboardShown)
    }

    func testOnboardWhenForcedButOnboarded() {
        // Given
        preferences.onboarded = true

        // When
        let isOnboardShown = sut.onboardIfNecessary(forced: true)

        // Then
        XCTAssertTrue(isOnboardShown)
    }
}
