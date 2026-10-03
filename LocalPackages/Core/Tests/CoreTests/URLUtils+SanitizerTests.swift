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

@testable import Core
import Testing

@Suite(.tags(.utilities))
struct URLUtilsPlusSanitizerTests {
    @Test(arguments: ["a b c", "ftp/example", "ftp//example", "ssh:/example", "https:/example"])
    func `invalid urls are not sanitized`(input: String) {
        #expect(URLUtils.Sanitizer.sanitize(input) == nil)
    }

    @Test(arguments: zip(["https://example/a?param=1",
                          "example.com/path?param=true",
                          "http://example.com/path?param=true",
                          "ssh://example.com/test?abc=",
                          "example.com"],
                         ["https://example/a?param=1",
                          "https://example.com/path?param=true",
                          "http://example.com/path?param=true",
                          "ssh://example.com/test?abc=",
                          "https://example.com"]))
    func `valid urls keep their scheme or default to https`(input: String, expected: String) {
        #expect(URLUtils.Sanitizer.sanitize(input) == expected)
    }
}
