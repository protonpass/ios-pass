//
// Data+BreachRangeTests.swift
// Proton Pass - Created on 30/09/2026.
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
import Foundation
import Testing

@Suite(.tags(.utilities))
struct DataBreachRangeTests {
    @Test func `parses suffix and count pairs`() {
        let body = Data("0018A45C4D1DEF81644B54AB7F969B88D65:10\n00D4F6E8FA6EECAD2A3AA415EEC418D38EC:2\n".utf8)

        #expect(body.parseBreachRange() == [.init(suffix: "0018A45C4D1DEF81644B54AB7F969B88D65", count: 10),
                                            .init(suffix: "00D4F6E8FA6EECAD2A3AA415EEC418D38EC", count: 2)])
    }

    @Test func `handles CRLF line endings and a missing trailing newline`() {
        let body = Data("AAA:1\r\nBBB:2".utf8)

        #expect(body.parseBreachRange() == [.init(suffix: "AAA", count: 1), .init(suffix: "BBB", count: 2)])
    }

    @Test func `uppercases suffixes and trims surrounding whitespace`() {
        let body = Data("  abc123 : 42 \n".utf8)

        #expect(body.parseBreachRange() == [.init(suffix: "ABC123", count: 42)])
    }

    @Test func `keeps padding entries with a zero count`() {
        let body = Data("AAA:5\nBBB:0\n".utf8)

        #expect(body.parseBreachRange() == [.init(suffix: "AAA", count: 5), .init(suffix: "BBB", count: 0)])
    }

    @Test func `splits only on the first colon`() {
        let body = Data("AAA:1:2\n".utf8)

        #expect(body.parseBreachRange() == [.init(suffix: "AAA", count: 0)])
    }

    @Test func `treats a non-numeric count as zero`() {
        let body = Data("AAA:abc\n".utf8)

        #expect(body.parseBreachRange() == [.init(suffix: "AAA", count: 0)])
    }

    @Test func `skips lines without a separator and blank lines`() {
        let body = Data("garbage\n\n\nAAA:3\n".utf8)

        #expect(body.parseBreachRange() == [.init(suffix: "AAA", count: 3)])
    }

    @Test func `returns no entries for an empty body`() {
        #expect(Data().parseBreachRange().isEmpty)
    }

    @Test func `returns no entries for a body that is not valid UTF-8`() {
        #expect(Data([0xFF, 0xFE, 0xFD]).parseBreachRange().isEmpty)
    }

    @Test func `counts by suffix keeps the last occurrence of a duplicated suffix`() {
        let entries: [BreachRangeEntry] = [.init(suffix: "AAA", count: 1),
                                           .init(suffix: "BBB", count: 2),
                                           .init(suffix: "AAA", count: 7)]

        #expect(entries.countsBySuffix == ["AAA": 7, "BBB": 2])
    }
}
