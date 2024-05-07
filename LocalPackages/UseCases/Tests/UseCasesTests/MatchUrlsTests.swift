//
// MatchUrlsTests.swift
// Proton Pass - Created on 02/05/2024.
// Copyright (c) 2024 Proton Technologies AG
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
//

@testable import UseCases
import XCTest

final class MatchUrlsTests: XCTestCase {
    var getRootDomain: (any GetRootDomainUseCase)!
    var sut: (any MatchUrlsUseCase)!

    override func setUp() {
        super.setUp()
        getRootDomain = GetRootDomain()
        sut = MatchUrls(getRootDomain: getRootDomain)
    }

    override func tearDown() {
        getRootDomain = nil
        sut = nil
        super.tearDown()
    }
}

extension MatchUrlsTests {
    func testNoSchemesShouldNotMatched() throws {
        XCTAssertEqual(try sut(XCTUnwrap(URL(string: "example.com")),
                               with: XCTUnwrap(URL(string: "https:/example.com"))),
                       .notMatched)

        XCTAssertEqual(try sut(XCTUnwrap(URL(string: "ssh://example.com")),
                               with: XCTUnwrap(URL(string: "https:/example.com"))),
                       .notMatched)
    }

    func testSchemeHttpOrHttps() throws {
        // `https` against `http` always not match
        XCTAssertEqual(try sut(XCTUnwrap(URL(string: "https://example.com")),
                               with: XCTUnwrap(URL(string: "http://example.com"))),
                       .notMatched)

        XCTAssertEqual(try sut(XCTUnwrap(URL(string: "example.com")),
                               with: XCTUnwrap(URL(string: "example.com"))),
                       .matched(1_000))

        XCTAssertEqual(try sut(XCTUnwrap(URL(string: "https://example.co.uk/dsjdh?sajjs")),
                               with: XCTUnwrap(URL(string: "https://example.co.uk"))),
                       .matched(1_000))

        XCTAssertEqual(try sut(XCTUnwrap(URL(string: "http://a.b.c.example.com")),
                               with: XCTUnwrap(URL(string: "http://a.b.c.example.com"))),
                       .matched(1_000))

        XCTAssertEqual(try sut(XCTUnwrap(URL(string: "http://a.b.c.example.com")),
                               with: XCTUnwrap(URL(string: "http://b.c.example.com"))),
                       .matched(999))

        XCTAssertEqual(try sut(XCTUnwrap(URL(string: "http://a.b.c.example.com")),
                               with: XCTUnwrap(URL(string: "https://c.example.com"))),
                       .matched(998))

        XCTAssertEqual(try sut(XCTUnwrap(URL(string: "https://a.b.c.example.com")),
                               with: XCTUnwrap(URL(string: "https://example.com"))),
                       .matched(997))
    }

    func testCustomSchemes() throws {
        XCTAssertEqual(try sut(XCTUnwrap(URL(string: "ssh://example.com")),
                               with: XCTUnwrap(URL(string: "ftp://example.com"))),
                       .notMatched)

        XCTAssertEqual(try sut(XCTUnwrap(URL(string: "ssh://example.com")),
                               with: XCTUnwrap(URL(string: "ssh://example.com/path?query="))),
                       .matched(1_000))
    }
}
