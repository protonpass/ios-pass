//  
// ItemFlagableTests.swift
// Proton Pass - Created on 04/06/2026.
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

import Foundation
@testable import Entities
import Testing

// MARK: - Test Helper

struct MockItem: ItemFlagable {
    var flags: Int
}

// MARK: - Tests

@Suite(.tags(.entity))
struct ItemFlagableTests {

    // MARK: - monitoringDisabled

    @Test func `monitoringDisabled is true when bit 0 is set`() {
        let item = MockItem(flags: 1 << 0)
        #expect(item.monitoringDisabled == true)
    }

    @Test func `monitoringDisabled is false when bit 0 is not set`() {
        let item = MockItem(flags: 0)
        #expect(item.monitoringDisabled == false)
    }

    // MARK: - isBreached

    @Test func `isBreached is true when bit 1 is set`() {
        let item = MockItem(flags: 1 << 1)
        #expect(item.isBreached == true)
    }

    @Test func `isBreached is false when bit 1 is not set`() {
        let item = MockItem(flags: 0)
        #expect(item.isBreached == false)
    }

    // MARK: - isBreachedAndMonitored

    @Test func `isBreachedAndMonitored is true when breached and monitoring enabled`() {
        let item = MockItem(flags: 1 << 1) // isBreached only
        #expect(item.isBreachedAndMonitored == true)
    }

    @Test func `isBreachedAndMonitored is false when breached but monitoring disabled`() {
        let item = MockItem(flags: (1 << 1) | (1 << 0)) // isBreached + monitoringDisabled
        #expect(item.isBreachedAndMonitored == false)
    }

    @Test func `isBreachedAndMonitored is false when not breached`() {
        let item = MockItem(flags: 0)
        #expect(item.isBreachedAndMonitored == false)
    }

    // MARK: - isAliasEnabled

    @Test func `isAliasEnabled is false when aliasDisabled flag is set`() {
        let item = MockItem(flags: 1 << 2)
        #expect(item.isAliasEnabled == false)
    }

    @Test func `isAliasEnabled is true when aliasDisabled flag is not set`() {
        let item = MockItem(flags: 0)
        #expect(item.isAliasEnabled == true)
    }

    // MARK: - hasFiles

    @Test func `hasFiles is true when bit 3 is set`() {
        let item = MockItem(flags: 1 << 3)
        #expect(item.hasFiles == true)
    }

    @Test func `hasFiles is false when bit 3 is not set`() {
        let item = MockItem(flags: 0)
        #expect(item.hasFiles == false)
    }

    // MARK: - hasHadFiles

    @Test func `hasHadFiles is true when bit 4 is set`() {
        let item = MockItem(flags: 1 << 4)
        #expect(item.hasHadFiles == true)
    }

    @Test func `hasHadFiles is false when bit 4 is not set`() {
        let item = MockItem(flags: 0)
        #expect(item.hasHadFiles == false)
    }

    // MARK: - weakPasswordCheckDisabled

    @Test func `weakPasswordCheckDisabled is true when bit 5 is set`() {
        let item = MockItem(flags: 1 << 5)
        #expect(item.weakPasswordCheckDisabled == true)
    }

    @Test func `weakPasswordCheckDisabled is false when bit 5 is not set`() {
        let item = MockItem(flags: 0)
        #expect(item.weakPasswordCheckDisabled == false)
    }

    // MARK: - compromisedPasswordCheckDisabled

    @Test func `compromisedPasswordCheckDisabled is true when bit 6 is set`() {
        let item = MockItem(flags: 1 << 6)
        #expect(item.compromisedPasswordCheckDisabled == true)
    }

    @Test func `compromisedPasswordCheckDisabled is false when bit 6 is not set`() {
        let item = MockItem(flags: 0)
        #expect(item.compromisedPasswordCheckDisabled == false)
    }

    // MARK: - reusedPasswordCheckDisabled

    @Test func `reusedPasswordCheckDisabled is true when bit 7 is set`() {
        let item = MockItem(flags: 1 << 7)
        #expect(item.reusedPasswordCheckDisabled == true)
    }

    @Test func `reusedPasswordCheckDisabled is false when bit 7 is not set`() {
        let item = MockItem(flags: 0)
        #expect(item.reusedPasswordCheckDisabled == false)
    }

    // MARK: - twoFACheckDisabled

    @Test func `twoFACheckDisabled is true when bit 8 is set`() {
        let item = MockItem(flags: 1 << 8)
        #expect(item.twoFACheckDisabled == true)
    }

    @Test func `twoFACheckDisabled is false when bit 8 is not set`() {
        let item = MockItem(flags: 0)
        #expect(item.twoFACheckDisabled == false)
    }

    // MARK: - Multiple flags

    @Test func `multiple flags can be set simultaneously without interference`() {
        let item = MockItem(flags: (1 << 1) | (1 << 3) | (1 << 5))
        #expect(item.isBreached == true)
        #expect(item.hasFiles == true)
        #expect(item.weakPasswordCheckDisabled == true)
        #expect(item.monitoringDisabled == false)
        #expect(item.hasHadFiles == false)
        #expect(item.twoFACheckDisabled == false)
    }

    @Test func `zero flags means all properties return their 'off' state`() {
        let item = MockItem(flags: 0)
        #expect(item.monitoringDisabled == false)
        #expect(item.isBreached == false)
        #expect(item.isBreachedAndMonitored == false)
        #expect(item.isAliasEnabled == true) // inverted flag
        #expect(item.hasFiles == false)
        #expect(item.hasHadFiles == false)
        #expect(item.weakPasswordCheckDisabled == false)
        #expect(item.compromisedPasswordCheckDisabled == false)
        #expect(item.reusedPasswordCheckDisabled == false)
        #expect(item.twoFACheckDisabled == false)
    }
}
