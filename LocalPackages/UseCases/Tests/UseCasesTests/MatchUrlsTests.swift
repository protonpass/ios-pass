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

import Entities
import Foundation
import Testing
import UseCases

@Suite(.tags(.useCase))
struct MatchUrlsTests {
    private let sut: any MatchUrlsUseCase = MatchUrls(getRootDomain: GetRootDomain())

    @Test(arguments: [
        (left: "example.com", right: "https:/example.com"),
        (left: "ssh://example.com", right: "https:/example.com")
    ])
    func `urls without a scheme or host do not match a different url`(left: String, right: String) throws {
        #expect(try match(left, right) == .notMatched)
    }

    @Test(arguments: [
        (left: "https://example.com", right: "http://example.com", expected: UrlMatchResult.notMatched),
        (left: "example.com", right: "example.com", expected: .matched(1_000)),
        (left: "https://example.co.uk/dsjdh?sajjs", right: "https://example.co.uk", expected: .matched(1_000)),
        (left: "http://a.b.c.example.com", right: "http://a.b.c.example.com", expected: .matched(1_000)),
        (left: "http://a.b.c.example.com", right: "http://b.c.example.com", expected: .matched(999)),
        (left: "http://a.b.c.example.com", right: "https://c.example.com", expected: .matched(998)),
        (left: "https://a.b.c.example.com", right: "https://example.com", expected: .matched(997))
    ])
    func `http urls score lower per differing subdomain and https never matches http`(left: String,
                                                                                      right: String,
                                                                                      expected: UrlMatchResult) throws {
        #expect(try match(left, right) == expected)
    }

    @Test(arguments: [
        (left: "ssh://example.com", right: "ftp://example.com", expected: UrlMatchResult.notMatched),
        (left: "ssh://example.com", right: "ssh://example.com/path?query=", expected: .matched(1_000))
    ])
    func `custom scheme urls match only on the same scheme and host`(left: String,
                                                                     right: String,
                                                                     expected: UrlMatchResult) throws {
        #expect(try match(left, right) == expected)
    }
}

private extension MatchUrlsTests {
    func match(_ left: String, _ right: String) throws -> UrlMatchResult {
        try sut(#require(URL(string: left)), with: #require(URL(string: right)))
    }
}
