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
    func testNoSchemesShouldNotMatched() throws {
        let sut = URLUtils.Matcher.default
        XCTAssertFalse(sut.isMatched(try XCTUnwrap(URL(string: "example.com")),
                                     try XCTUnwrap(URL(string: "example.com"))))

        XCTAssertFalse(sut.isMatched(try XCTUnwrap(URL(string: "example.com")),
                                     try XCTUnwrap(URL(string: "https://example.com"))))
    }

    func testSchemeHttpOrHttps() throws {
        let sut = URLUtils.Matcher.default
        XCTAssertFalse(sut.isMatched(try XCTUnwrap(URL(string: "example.com")),
                                     try XCTUnwrap(URL(string: "example.com"))))

        XCTAssertFalse(sut.isMatched(try XCTUnwrap(URL(string: "ssh://example.com")),
                                     try XCTUnwrap(URL(string: "ssh://example.com"))))

        XCTAssertTrue(sut.isMatched(try XCTUnwrap(URL(string: "http://example.co.uk/dsjdh?sajjs")),
                                    try XCTUnwrap(URL(string: "http://example.co.uk"))))

        XCTAssertTrue(sut.isMatched(try XCTUnwrap(URL(string: "http://a.b.cexample.dni.us")),
                                    try XCTUnwrap(URL(string: "http://d.example.dni.us"))))

        XCTAssertTrue(sut.isMatched(try XCTUnwrap(URL(string: "https://example.com")),
                                    try XCTUnwrap(URL(string: "https://example.com"))))

        XCTAssertTrue(sut.isMatched(try XCTUnwrap(URL(string: "https://a.b.cexample.com")),
                                    try XCTUnwrap(URL(string: "https://d.example.com"))))

        XCTAssertTrue(sut.isMatched(try XCTUnwrap(URL(string: "http://example.com")),
                                    try XCTUnwrap(URL(string: "https://example.com"))))

        XCTAssertTrue(sut.isMatched(try XCTUnwrap(URL(string: "http://a.b.cexample.com")),
                                    try XCTUnwrap(URL(string: "https://d.example.com"))))
    }

    func testCustomSchemes() throws {
        let sut = URLUtils.Matcher(allowedSchemes: ["ssh", "ftp"])
        XCTAssertTrue(sut.isMatched(try XCTUnwrap(URL(string: "ssh://example.com")),
                                    try XCTUnwrap(URL(string: "ssh://example.com"))))

        XCTAssertFalse(sut.isMatched(try XCTUnwrap(URL(string: "ssh://example.com")),
                                     try XCTUnwrap(URL(string: "ftp://example.com"))))

        XCTAssertFalse(sut.isMatched(try XCTUnwrap(URL(string: "ssh://example.com")),
                                     try XCTUnwrap(URL(string: "ssh://subdomain.example.com"))))
    }
}
