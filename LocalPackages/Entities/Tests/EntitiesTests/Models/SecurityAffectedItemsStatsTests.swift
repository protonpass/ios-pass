//
// SecurityAffectedItemsStatsTests.swift
// Proton Pass - Created on 29/09/2026.
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
struct SecurityAffectedItemsStatsTests {
    @Test
    func `empty list yields zero counts and passes reused count through`() {
        let stats = [SecurityAffectedItem]().stats(reusedPasswordCount: 4)
        #expect(stats == WeaknessStats(counts: [.weakPassword: 0, .reusedPassword: 4, .missing2FA: 0],
                                       excludedItems: 0))
    }

    @Test
    func `counts weak password and missing 2FA from detected weaknesses`() {
        let items: [SecurityAffectedItem] = [
            .make(detected: [.weakPassword]),
            .make(detected: [.missing2FA]),
            .make(detected: [.weakPassword, .missing2FA]),
            .make(detected: [])
        ]

        let stats = items.stats(reusedPasswordCount: 0)

        #expect(stats.count(for: .weakPassword) == 2)
        #expect(stats.count(for: .missing2FA) == 2)
        #expect(stats.excludedItems == 0)
    }

    @Test
    func `reused and compromised counts ignore per-item detections`() {
        let items: [SecurityAffectedItem] = [
            .make(detected: [.reusedPassword, .compromisedPassword]),
            .make(detected: [.reusedPassword])
        ]

        let stats = items.stats(reusedPasswordCount: 7)

        #expect(stats.count(for: .reusedPassword) == 7)
        #expect(stats.count(for: .compromisedPassword) == 0)
    }

    @Test
    func `suppressed checks are not counted but the item is excluded`() {
        let items: [SecurityAffectedItem] = [
            .make(detected: [.weakPassword, .missing2FA], flags: .skipWeakPasswordCheck),
            .make(detected: [.missing2FA], flags: .skip2FACheck)
        ]

        let stats = items.stats(reusedPasswordCount: 0)

        #expect(stats.count(for: .weakPassword) == 0)
        #expect(stats.count(for: .missing2FA) == 1)
        #expect(stats.excludedItems == 2)
    }

    @Test
    func `fully excluded item contributes only to excluded count`() {
        let items: [SecurityAffectedItem] = [
            .make(detected: [.weakPassword, .missing2FA], flags: .monitoringDisabled),
            .make(detected: [.weakPassword])
        ]

        let stats = items.stats(reusedPasswordCount: 0)

        #expect(stats.count(for: .weakPassword) == 1)
        #expect(stats.count(for: .missing2FA) == 0)
        #expect(stats.excludedItems == 1)
    }

    @Test
    func `suppressing an undetected check still counts the item as excluded`() {
        let items: [SecurityAffectedItem] = [
            .make(detected: [], flags: .skipReusedPasswordCheck)
        ]

        let stats = items.stats(reusedPasswordCount: 0)

        #expect(stats.count(for: .weakPassword) == 0)
        #expect(stats.count(for: .missing2FA) == 0)
        #expect(stats.excludedItems == 1)
    }

    @Test
    func `unrelated flags do not mark the item as excluded`() {
        let items: [SecurityAffectedItem] = [
            .make(detected: [.weakPassword], flags: [.isBreached, .hasFiles, .aliasDisabled])
        ]

        let stats = items.stats(reusedPasswordCount: 0)

        #expect(stats.count(for: .weakPassword) == 1)
        #expect(stats.excludedItems == 0)
    }
}

private extension SecurityAffectedItem {
    static func make(detected: Set<WeaknessKind>, flags: ItemFlags = []) -> SecurityAffectedItem {
        let item = SymmetricallyEncryptedItem.random(item: .random(flags: flags.rawValue))
        return .init(item: item,
                     detected: detected,
                     display: .mock(itemId: item.itemId, shareId: item.shareId),
                     reuseGroup: nil)
    }
}
