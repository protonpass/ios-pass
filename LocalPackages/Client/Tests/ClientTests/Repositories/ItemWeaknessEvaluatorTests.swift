//
// ItemWeaknessEvaluatorTests.swift
// Proton Pass - Created on 17/06/2026.
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
import Entities
import EntitiesMocks
import Testing

/// Exercises the pure detection policy with the real scorer/2FA checker (same components and known
/// inputs the repository tests rely on), so the rules are pinned without standing up the repository.
@Suite(.tags(.repository))
struct ItemWeaknessEvaluatorTests {
    let sut = ItemWeaknessEvaluator()

    /// A password the real scorer rates non-strong vs. one it rates strong.
    private let weakPassword = "aaaaa"
    private let strongPassword = "Ageless6-Evidence0-Detonator1-Cider4-Synthesis4"

    @Test
    func `Weak password is detected; strong is not`() {
        #expect(sut.evaluate(.mock(username: "test", password: weakPassword), isReused: false)
            .contains(.weakPassword))
        #expect(!sut.evaluate(.mock(username: "test", password: strongPassword), isReused: false)
            .contains(.weakPassword))
    }

    @Test
    func `isReused drives the reused weakness`() {
        #expect(sut.evaluate(.mock(password: strongPassword), isReused: true).contains(.reusedPassword))
        #expect(!sut.evaluate(.mock(password: strongPassword), isReused: false).contains(.reusedPassword))
    }

    @Test
    func `Missing2FA needs an eligible URL, no TOTP and no passkeys`() {
        let missing = LogInItemData.mock(username: "test",
                                         password: strongPassword,
                                         totpUri: "",
                                         urls: ["google.com"])
        #expect(sut.evaluate(missing, isReused: false).contains(.missing2FA))

        let withTotp = LogInItemData.mock(username: "test",
                                          password: strongPassword,
                                          totpUri: "otpauth://totp/Example",
                                          urls: ["google.com"])
        #expect(!sut.evaluate(withTotp, isReused: false).contains(.missing2FA))
    }
}
