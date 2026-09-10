//
// FeatureFlagsRepositoryMockTests.swift
// Proton Pass - Created on 10/09/2026.
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

@testable import Client
import ClientMocks
import ProtonCoreFeatureFlags
import Testing

/// `ProtonCoreFeatureFlags` backs `isEnabled` and `getFlag` with same-signature protocol
/// extensions that call themselves, so dropping a witness from the mock does not fail to
/// compile - it recurses until the stack overflows. These read the flag through every
/// overload so that regression shows up here rather than inside an unrelated suite.
@Suite(.tags(.repository))
struct FeatureFlagsRepositoryMockTests {
    private let flag = FeatureFlagType.passAutofillUrlAdvancedModes

    @Test(.timeLimit(.minutes(1)))
    func `every isEnabled overload reports the stubbed value`() {
        let enabled = FeatureFlagsRepositoryMock(isEnabled: { _ in true })
        #expect(enabled.isEnabled(flag, reloadValue: true))
        #expect(enabled.isEnabled(flag, for: "user-id", reloadValue: true))
        #expect(enabled.getFlag(flag, for: "user-id", reloadValue: true)?.enabled == true)

        let disabled = FeatureFlagsRepositoryMock()
        #expect(!disabled.isEnabled(flag, reloadValue: true))
        #expect(!disabled.isEnabled(flag, for: "user-id", reloadValue: true))
        #expect(disabled.getFlag(flag, for: "user-id", reloadValue: true)?.enabled == false)
    }

    @Test(.timeLimit(.minutes(1)))
    func `flagsUpdates yields rather than hanging on a dropped continuation`() async throws {
        let sut = FeatureFlagsRepositoryMock()
        sut.simulateFlagsUpdate(for: "user-id")

        var received: String?
        for await userId in sut.flagsUpdates {
            received = userId
            break
        }

        #expect(received == "user-id")
    }
}
