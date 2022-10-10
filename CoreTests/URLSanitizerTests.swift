//
// URLSanitizerTests.swift
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

final class URLSanitizerTests: XCTestCase {
    func testSanitization() {
        XCTAssertNil(URLSanitizer.sanitize("a b c"))
        XCTAssertNil(URLSanitizer.sanitize("ftp/example"))
        XCTAssertNil(URLSanitizer.sanitize("ftp//example"))
        XCTAssertNil(URLSanitizer.sanitize("ssh:/example"))
        XCTAssertNil(URLSanitizer.sanitize("https:/example"))
        XCTAssertNil(URLSanitizer.sanitize("https://example❤️.com"))
        XCTAssertEqual(URLSanitizer.sanitize("example.com/path?param=true"),
                       "https://example.com/path?param=true")
        XCTAssertEqual(URLSanitizer.sanitize("http://example.com/path?param=true"),
                       "http://example.com/path?param=true")
        XCTAssertEqual(URLSanitizer.sanitize("ssh://example.com/test?abc="),
                       "ssh://example.com/test?abc=")
        XCTAssertEqual(URLSanitizer.sanitize("example.com"), "https://example.com")
    }
}
