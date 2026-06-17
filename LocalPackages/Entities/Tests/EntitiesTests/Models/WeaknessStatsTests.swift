//
// WeaknessStatsTests.swift
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

@testable import Entities
import Testing

@Suite(.tags(.entity))
struct WeaknessStatsTests {
    @Test("count(for:) returns the stored count or 0 for missing keys")
    func countForKind() {
        let stats = WeaknessStats(counts: [.weakPassword: 3, .reusedPassword: 1], excludedItems: 2)
        #expect(stats.count(for: .weakPassword) == 3)
        #expect(stats.count(for: .reusedPassword) == 1)
        #expect(stats.count(for: .missing2FA) == 0)
        #expect(stats.count(for: .compromisedPassword) == 0)
        #expect(stats.excludedItems == 2)
    }

    @Test("hasWeakOrReusedPasswords reflects only weak + reused counts")
    func hasWeakOrReused() {
        #expect(!WeaknessStats(counts: [:], excludedItems: 0).hasWeakOrReusedPasswords)
        #expect(WeaknessStats(counts: [.weakPassword: 1], excludedItems: 0).hasWeakOrReusedPasswords)
        #expect(WeaknessStats(counts: [.reusedPassword: 1], excludedItems: 0).hasWeakOrReusedPasswords)
        #expect(!WeaknessStats(counts: [.missing2FA: 5], excludedItems: 0).hasWeakOrReusedPasswords)
    }
}
