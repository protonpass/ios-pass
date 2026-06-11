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

@Suite("ItemFlagable Tests")
struct ItemFlagableTests {

    // MARK: - monitoringDisabled

    @Test("monitoringDisabled is true when bit 0 is set")
    func monitoringDisabled_whenFlagSet_returnsTrue() {
        let item = MockItem(flags: 1 << 0)
        #expect(item.monitoringDisabled == true)
    }

    @Test("monitoringDisabled is false when bit 0 is not set")
    func monitoringDisabled_whenFlagNotSet_returnsFalse() {
        let item = MockItem(flags: 0)
        #expect(item.monitoringDisabled == false)
    }

    // MARK: - isBreached

    @Test("isBreached is true when bit 1 is set")
    func isBreached_whenFlagSet_returnsTrue() {
        let item = MockItem(flags: 1 << 1)
        #expect(item.isBreached == true)
    }

    @Test("isBreached is false when bit 1 is not set")
    func isBreached_whenFlagNotSet_returnsFalse() {
        let item = MockItem(flags: 0)
        #expect(item.isBreached == false)
    }

    // MARK: - isBreachedAndMonitored

    @Test("isBreachedAndMonitored is true when breached and monitoring enabled")
    func isBreachedAndMonitored_whenBreachedAndMonitored_returnsTrue() {
        let item = MockItem(flags: 1 << 1) // isBreached only
        #expect(item.isBreachedAndMonitored == true)
    }

    @Test("isBreachedAndMonitored is false when breached but monitoring disabled")
    func isBreachedAndMonitored_whenBreachedButMonitoringDisabled_returnsFalse() {
        let item = MockItem(flags: (1 << 1) | (1 << 0)) // isBreached + monitoringDisabled
        #expect(item.isBreachedAndMonitored == false)
    }

    @Test("isBreachedAndMonitored is false when not breached")
    func isBreachedAndMonitored_whenNotBreached_returnsFalse() {
        let item = MockItem(flags: 0)
        #expect(item.isBreachedAndMonitored == false)
    }

    // MARK: - isAliasEnabled

    @Test("isAliasEnabled is false when aliasDisabled flag is set")
    func isAliasEnabled_whenAliasDisabledFlagSet_returnsFalse() {
        let item = MockItem(flags: 1 << 2)
        #expect(item.isAliasEnabled == false)
    }

    @Test("isAliasEnabled is true when aliasDisabled flag is not set")
    func isAliasEnabled_whenAliasDisabledFlagNotSet_returnsTrue() {
        let item = MockItem(flags: 0)
        #expect(item.isAliasEnabled == true)
    }

    // MARK: - hasFiles

    @Test("hasFiles is true when bit 3 is set")
    func hasFiles_whenFlagSet_returnsTrue() {
        let item = MockItem(flags: 1 << 3)
        #expect(item.hasFiles == true)
    }

    @Test("hasFiles is false when bit 3 is not set")
    func hasFiles_whenFlagNotSet_returnsFalse() {
        let item = MockItem(flags: 0)
        #expect(item.hasFiles == false)
    }

    // MARK: - hasHadFiles

    @Test("hasHadFiles is true when bit 4 is set")
    func hasHadFiles_whenFlagSet_returnsTrue() {
        let item = MockItem(flags: 1 << 4)
        #expect(item.hasHadFiles == true)
    }

    @Test("hasHadFiles is false when bit 4 is not set")
    func hasHadFiles_whenFlagNotSet_returnsFalse() {
        let item = MockItem(flags: 0)
        #expect(item.hasHadFiles == false)
    }

    // MARK: - weakPasswordCheckDisabled

    @Test("weakPasswordCheckDisabled is true when bit 5 is set")
    func weakPasswordCheckDisabled_whenFlagSet_returnsTrue() {
        let item = MockItem(flags: 1 << 5)
        #expect(item.weakPasswordCheckDisabled == true)
    }

    @Test("weakPasswordCheckDisabled is false when bit 5 is not set")
    func weakPasswordCheckDisabled_whenFlagNotSet_returnsFalse() {
        let item = MockItem(flags: 0)
        #expect(item.weakPasswordCheckDisabled == false)
    }

    // MARK: - compromisedPasswordCheckDisabled

    @Test("compromisedPasswordCheckDisabled is true when bit 6 is set")
    func compromisedPasswordCheckDisabled_whenFlagSet_returnsTrue() {
        let item = MockItem(flags: 1 << 6)
        #expect(item.compromisedPasswordCheckDisabled == true)
    }

    @Test("compromisedPasswordCheckDisabled is false when bit 6 is not set")
    func compromisedPasswordCheckDisabled_whenFlagNotSet_returnsFalse() {
        let item = MockItem(flags: 0)
        #expect(item.compromisedPasswordCheckDisabled == false)
    }

    // MARK: - reusedPasswordCheckDisabled

    @Test("reusedPasswordCheckDisabled is true when bit 7 is set")
    func reusedPasswordCheckDisabled_whenFlagSet_returnsTrue() {
        let item = MockItem(flags: 1 << 7)
        #expect(item.reusedPasswordCheckDisabled == true)
    }

    @Test("reusedPasswordCheckDisabled is false when bit 7 is not set")
    func reusedPasswordCheckDisabled_whenFlagNotSet_returnsFalse() {
        let item = MockItem(flags: 0)
        #expect(item.reusedPasswordCheckDisabled == false)
    }

    // MARK: - twoFACheckDisabled

    @Test("twoFACheckDisabled is true when bit 8 is set")
    func twoFACheckDisabled_whenFlagSet_returnsTrue() {
        let item = MockItem(flags: 1 << 8)
        #expect(item.twoFACheckDisabled == true)
    }

    @Test("twoFACheckDisabled is false when bit 8 is not set")
    func twoFACheckDisabled_whenFlagNotSet_returnsFalse() {
        let item = MockItem(flags: 0)
        #expect(item.twoFACheckDisabled == false)
    }

    // MARK: - Multiple flags

    @Test("Multiple flags can be set simultaneously without interference")
    func multipleFlags_setTogether_areIndependent() {
        let item = MockItem(flags: (1 << 1) | (1 << 3) | (1 << 5))
        #expect(item.isBreached == true)
        #expect(item.hasFiles == true)
        #expect(item.weakPasswordCheckDisabled == true)
        #expect(item.monitoringDisabled == false)
        #expect(item.hasHadFiles == false)
        #expect(item.twoFACheckDisabled == false)
    }

    @Test("Zero flags means all properties return their 'off' state")
    func noFlags_allPropertiesReturnOffState() {
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
