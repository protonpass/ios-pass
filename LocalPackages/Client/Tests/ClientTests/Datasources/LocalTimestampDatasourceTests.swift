//  
// LocalTimestampDatasourceTests.swift
// Proton Pass - Created on 07/07/2026.
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
import Testing
@testable import Client

@Suite("LocalTimestampDatasource")
final class LocalTimestampDatasourceTests {
    private let suiteName = "LocalTimestampDatasourceTests.\(UUID().uuidString)"
    private let defaults: UserDefaults
    private let sut: LocalTimestampDatasource

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        sut = LocalTimestampDatasource(userDefault: defaults)
    }

    deinit {
        defaults.removePersistentDomain(forName: suiteName)
    }

    // MARK: - getTimestamp

    @Test func `returns nil when no value exists for the key`() {
        #expect(sut.getTimestamp(key: "absent") == nil)
    }

    @Test func `distinguishes a stored zero from an absent key`() {
        sut.setTimestamp(0, key: "key")
        #expect(sut.getTimestamp(key: "key") == 0)
    }

    @Test(arguments: [1, -1, 1_736_000_000, Int.max, Int.min])
    func `round-trips stored values`(value: Int) {
        sut.setTimestamp(value, key: "key")
        #expect(sut.getTimestamp(key: "key") == value)
    }

    // MARK: - setTimestamp

    @Test func `overwrites an existing value`() {
        sut.setTimestamp(1, key: "key")
        sut.setTimestamp(2, key: "key")
        #expect(sut.getTimestamp(key: "key") == 2)
    }

    @Test func `setting nil removes the stored value`() {
        sut.setTimestamp(42, key: "key")
        sut.setTimestamp(nil, key: "key")

        #expect(sut.getTimestamp(key: "key") == nil)
        #expect(defaults.object(forKey: "key") == nil, "value must be removed, not masked")
    }

    @Test func `setting nil for an absent key is a no-op`() {
        sut.setTimestamp(nil, key: "key")
        #expect(sut.getTimestamp(key: "key") == nil)
    }

    @Test func `values are isolated per key`() {
        sut.setTimestamp(1, key: "a")
        sut.setTimestamp(2, key: "b")
        sut.setTimestamp(nil, key: "a")

        #expect(sut.getTimestamp(key: "a") == nil)
        #expect(sut.getTimestamp(key: "b") == 2)
    }

    @Test func `returns nil when the key holds a non-numeric value`() {
        defaults.set("not a timestamp", forKey: "key")
        #expect(sut.getTimestamp(key: "key") == nil)
    }
}
