//
// PasskeyAssertionPrfInputTests.swift
// Proton Pass - Created on 14/10/2026.
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

import Entities
import Foundation
import Testing

@Suite(.tags(.entity))
struct PasskeyAssertionPrfInputTests {
    private let credentialId = Data([1, 2, 3])
    private let globalValues = PasskeyPrfValues(first: Data([7]), second: nil)
    private let credentialValues = PasskeyPrfValues(first: Data([8]), second: Data([9]))

    @Test func `per-credential values take precedence over global values`() {
        let sut = PasskeyAssertionPrfInput(values: globalValues,
                                           valuesByCredentialId: [credentialId: credentialValues])

        #expect(sut.values(for: credentialId) == credentialValues)
    }

    @Test func `global values are used when the credential has no dedicated values`() {
        let sut = PasskeyAssertionPrfInput(values: globalValues,
                                           valuesByCredentialId: [Data([4]): credentialValues])

        #expect(sut.values(for: credentialId) == globalValues)
    }

    @Test func `no values are returned when neither global nor per-credential values match`() {
        let sut = PasskeyAssertionPrfInput(values: nil, valuesByCredentialId: [Data([4]): credentialValues])

        #expect(sut.values(for: credentialId) == nil)
    }
}
