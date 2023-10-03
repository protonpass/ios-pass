//
// URLUtils+SanitizerTests.swift
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

// swiftlint:disable force_try
@testable import Core
import XCTest

final class URLUtilsPlusSanitizerTests: XCTestCase {
    func testSanitization() {
        // Invalid URLs
        XCTAssertNil(URLUtils.Sanitizer.sanitize("a b c"))
        XCTAssertNil(URLUtils.Sanitizer.sanitize("ftp/example"))
        XCTAssertNil(URLUtils.Sanitizer.sanitize("ftp//example"))
        XCTAssertNil(URLUtils.Sanitizer.sanitize("ssh:/example"))
        XCTAssertNil(URLUtils.Sanitizer.sanitize("https:/example"))
        XCTAssertNil(URLUtils.Sanitizer.sanitize("https://example"))

        // Valid URLs
        XCTAssertEqual(URLUtils.Sanitizer.sanitize("example.com/path?param=true"),
                       "https://example.com/path?param=true")

        XCTAssertEqual(URLUtils.Sanitizer.sanitize("http://example.com/path?param=true"),
                       "http://example.com/path?param=true")

        XCTAssertEqual(URLUtils.Sanitizer.sanitize("ssh://example.com/test?abc="),
                       "ssh://example.com/test?abc=")

        XCTAssertEqual(URLUtils.Sanitizer.sanitize("example.com"), "https://example.com")
    }

    func testSanitizeAndGetRootDomain() {
        guard let parser = try? DomainParser() else {
            XCTFail("Should not reach the part of guard")
            return
        }
        let test: (String, String) -> Void = { input, output in
            XCTAssertEqual(URLUtils.Sanitizer.sanitizeAndGetRootDomain(input,
                                                                       domainParser: parser),
                           output)
        }
        test("example.com/path?param=true", "example.com")
        test("ssh://example.com/test?abc=", "example.com")
        test("https://account.proton.me/path?param=true", "proton.me")
        test("https://gitlab.tech.proton.me/test?abc=", "proton.me")
        test("https://gitlab.tech.proton.co.uk/test?abc=", "proton.co.uk")
    }
}
