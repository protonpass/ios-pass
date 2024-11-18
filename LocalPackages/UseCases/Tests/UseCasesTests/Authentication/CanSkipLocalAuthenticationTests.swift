//
// CanSkipLocalAuthenticationTests.swift
// Proton Pass - Created on 15/11/2024.
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

import Core
import Entities
import Foundation
import Testing
import UseCases

private struct MockedCurrentDateProvider: CurrentDateProviderProtocol {
    var currentDate = Date.now
    func getCurrentDate() -> Date { currentDate }
}

struct CanSkipLocalAuthenticationTests {
    let sut: any CanSkipLocalAuthenticationUseCase
    private var currentDateProvider: MockedCurrentDateProvider!

    init() {
        currentDateProvider = .init()
        sut = CanSkipLocalAuthentication(currentDateProvider: currentDateProvider)
    }

    @Test("Can not skip when no lastActiveTimestamp")
    func canNotSkipWhenNoLastActiveTimestamp() {
        let canSkip = sut.execute(appLockTime: .oneHour, lastActiveTimestamp: nil)
        #expect(!canSkip)
    }

    @Test("Can not skip when inactive for too long")
    mutating func canNotSkipWhenInactiveForTooLong() {
        // Given
        let now = Date.now
        let threeMinutesAgo = now.timeIntervalSince1970 - 3 * 60

        // When
        currentDateProvider.currentDate = now
        let canSkip = sut.execute(appLockTime: .twoMinutes,
                                  lastActiveTimestamp: threeMinutesAgo)

        // Then
        #expect(!canSkip)
    }

    @Test("Can skip when recently active")
    mutating func canSkipWhenRecentlyActive() {
        // Given
        let now = Date.now
        let oneMinutesAgo = now.timeIntervalSince1970 - 60

        // When
        currentDateProvider.currentDate = now
        let canSkip = sut.execute(appLockTime: .twoMinutes,
                                  lastActiveTimestamp: oneMinutesAgo)

        // Then
        #expect(canSkip)
    }
}
