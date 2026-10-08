//
// SecurityAffectedItemTests.swift
// Proton Pass - Created on 07/10/2026.
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
import EntitiesMocks
import Testing

@Suite(.tags(.entity))
struct SecurityAffectedItemTests {
    @Test func `nothing excluded keeps the item monitored`() {
        let item = makeItem(detected: [.weakPassword, .reusedPassword])
        #expect(!item.hasNothingMonitored)
    }

    @Test func `some detected weaknesses suppressed keeps the item monitored`() {
        let item = makeItem(detected: [.weakPassword, .reusedPassword], suppressed: [.weakPassword])
        #expect(!item.hasNothingMonitored)
    }

    @Test func `every detected weakness suppressed leaves nothing monitored`() {
        let item = makeItem(detected: [.weakPassword], suppressed: [.weakPassword, .missing2FA])
        #expect(item.hasNothingMonitored)
    }

    @Test func `full exclusion leaves nothing monitored`() {
        let item = makeItem(fullyExcluded: true, detected: [.weakPassword])
        #expect(item.hasNothingMonitored)
    }

    @Test func `no weakness and no exclusion keeps the item monitored`() {
        #expect(!makeItem().hasNothingMonitored)
    }

    @Test func `a single suppressed check makes the item excluded`() {
        let item = makeItem(detected: [.weakPassword, .reusedPassword], suppressed: [.weakPassword])
        #expect(item.isExcludedItem)
    }

    @Test func `a fully monitored item is not excluded`() {
        #expect(!makeItem(detected: [.weakPassword]).isExcludedItem)
    }

    @Test func `excluding sets full exclusion and suppresses only still active weaknesses`() {
        let item = makeItem(detected: [.missing2FA, .weakPassword, .reusedPassword],
                            suppressed: [.reusedPassword])
        #expect(item.flagsToExcludeFromMonitoring == [.skipHealthCheck(true),
                                                      .skipWeakPasswordCheck(true),
                                                      .skip2FACheck(true)])
    }

    @Test func `excluding an item without weaknesses only sets full exclusion`() {
        #expect(makeItem().flagsToExcludeFromMonitoring == [.skipHealthCheck(true)])
    }
}

private func makeItem(fullyExcluded: Bool = false,
                      detected: Set<WeaknessKind> = [],
                      suppressed: Set<WeaknessKind> = []) -> SecurityAffectedItem {
    let flags = fullyExcluded ? ItemFlags.monitoringDisabled.rawValue : 0
    let encrypted = SymmetricallyEncryptedItem.random(item: .random(flags: flags))
    return SecurityAffectedItem(item: encrypted,
                                detected: detected,
                                display: .mock(itemId: encrypted.itemId, shareId: encrypted.shareId),
                                suppressedChecks: suppressed,
                                reuseGroup: nil)
}
