//
// LocalAuthenticationStateTests.swift
// Proton Pass - Created on 18/08/2026.
// Copyright (c) 2026 Proton Technologies AG
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

@testable import Entities
import Testing

@Suite("LocalAuthenticationState Tests")
struct LocalAuthenticationStateTests {
    private static let maxAttemptCount = 3

    @Test("Failed attempt count maps to the lockout state",
          arguments: [(failedAttemptCount: 0, expected: LocalAuthenticationState.noAttempts),
                      (failedAttemptCount: 1, expected: .remainingAttempts(2)),
                      (failedAttemptCount: 2, expected: .lastAttempt),
                      (failedAttemptCount: 3, expected: .exhausted),
                      (failedAttemptCount: 4, expected: .exhausted)])
    func init_mapsFailedAttemptCountToState(failedAttemptCount: Int,
                                           expected: LocalAuthenticationState) {
        let state = LocalAuthenticationState(failedAttemptCount: failedAttemptCount,
                                            maxAttemptCount: Self.maxAttemptCount)
        #expect(state == expected)
    }

    @Test("A single max attempt goes straight from no attempts to exhausted")
    func init_whenOnlyOneAttemptAllowed_skipsIntermediateStates() {
        #expect(LocalAuthenticationState(failedAttemptCount: 0, maxAttemptCount: 1) == .noAttempts)
        #expect(LocalAuthenticationState(failedAttemptCount: 1, maxAttemptCount: 1) == .exhausted)
    }
}
