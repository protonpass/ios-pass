//
// WeaknessKindTests.swift
// Proton Pass - Created on 15/06/2026.
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

@Suite(.tags(.entity))
struct WeaknessKindTests {
    /// Pins the product-defined severity/display order. If this fails, the on-screen ordering
    /// of weakness categories has changed - confirm it is intentional before updating.
    @Test
    func `Display order is weak → compromised → reused → missing2FA`() {
        #expect(WeaknessKind.allCases.sorted() == [.weakPassword,
                                                   .compromisedPassword,
                                                   .reusedPassword,
                                                   .missing2FA])
    }

    @Test
    func `Display priorities are unique`() {
        let priorities = WeaknessKind.allCases.map(\.displayPriority)
        #expect(Set(priorities).count == WeaknessKind.allCases.count)
    }
}
