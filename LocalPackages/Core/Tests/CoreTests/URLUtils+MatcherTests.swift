//
// URLUtils+MatcherTests.swift
// Proton Pass - Created on 07/10/2022.
// Copyright (c) 2022 Proton Technologies AG
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

@testable import Core
import XCTest

final class URLUtilsPlusMatcherTests: XCTestCase {
    func testMatchResult() {
        XCTAssertEqual(URLUtils.Matcher.MatchResult.notMatched,
                       URLUtils.Matcher.MatchResult.notMatched)
        XCTAssertEqual(URLUtils.Matcher.MatchResult.matched(1_000),
                       URLUtils.Matcher.MatchResult.matched(1_000))
        XCTAssertNotEqual(URLUtils.Matcher.MatchResult.notMatched,
                          URLUtils.Matcher.MatchResult.matched(1_000))
        XCTAssertNotEqual(URLUtils.Matcher.MatchResult.matched(1_000),
                          URLUtils.Matcher.MatchResult.matched(500))
    }

    func testNoSchemesShouldNotMatched() throws {
        XCTAssertEqual(try URLUtils.Matcher.compare(XCTUnwrap(URL(string: "example.com")),
                                                    XCTUnwrap(URL(string: "example.com"))),
                       .notMatched)

        XCTAssertEqual(try URLUtils.Matcher.compare(XCTUnwrap(URL(string: "example.com")),
                                                    XCTUnwrap(URL(string: "https:/example.com"))),
                       .notMatched)

        XCTAssertEqual(try URLUtils.Matcher.compare(XCTUnwrap(URL(string: "ssh://example.com")),
                                                    XCTUnwrap(URL(string: "https:/example.com"))),
                       .notMatched)
    }

    func testSchemeHttpOrHttps() throws {
        // `https` against `http` always not match
        XCTAssertEqual(try URLUtils.Matcher.compare(XCTUnwrap(URL(string: "https://example.com")),
                                                    XCTUnwrap(URL(string: "http://example.com"))),
                       .notMatched)

        XCTAssertEqual(try URLUtils.Matcher.compare(XCTUnwrap(URL(string: "https://example.co.uk/dsjdh?sajjs")),
                                                    XCTUnwrap(URL(string: "https://example.co.uk"))),
                       .matched(1_000))

        XCTAssertEqual(try URLUtils.Matcher.compare(XCTUnwrap(URL(string: "http://a.b.c.example.com")),
                                                    XCTUnwrap(URL(string: "http://a.b.c.example.com"))),
                       .matched(1_000))

        XCTAssertEqual(try URLUtils.Matcher.compare(XCTUnwrap(URL(string: "http://a.b.c.example.com")),
                                                    XCTUnwrap(URL(string: "http://b.c.example.com"))),
                       .matched(999))

        XCTAssertEqual(try URLUtils.Matcher.compare(XCTUnwrap(URL(string: "http://a.b.c.example.com")),
                                                    XCTUnwrap(URL(string: "https://c.example.com"))),
                       .matched(998))

        XCTAssertEqual(try URLUtils.Matcher.compare(XCTUnwrap(URL(string: "https://a.b.c.example.com")),
                                                    XCTUnwrap(URL(string: "https://example.com"))),
                       .matched(997))
    }

    func testCustomSchemes() throws {
        XCTAssertEqual(try URLUtils.Matcher.compare(XCTUnwrap(URL(string: "ssh://example.com")),
                                                    XCTUnwrap(URL(string: "ftp://example.com"))),
                       .notMatched)

        XCTAssertEqual(try URLUtils.Matcher.compare(XCTUnwrap(URL(string: "ssh://example.com")),
                                                    XCTUnwrap(URL(string: "ssh://example.com/path?query="))),
                       .matched(1_000))
    }
}
