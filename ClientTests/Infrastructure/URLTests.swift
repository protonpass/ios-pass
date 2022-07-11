//
// URLTests.swift
// Proton Pass - Created on 11/07/2022.
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

@testable import Client
import XCTest

final class URLTests: XCTestCase {
    func testAppendingPathQueryItemsCorrectly() throws {
        let baseURL = try XCTUnwrap(URL(string: "https://example.com"))

        let url1 = baseURL.appending(path: "/path/to/something")
        XCTAssertEqual(url1.absoluteString, "https://example.com/path/to/something")

        let url2 = baseURL.appending(path: "/path",
                                     queryItems: [.init(name: "firstName", value: "John"),
                                                  .init(name: "lastName", value: "Doe")])
        XCTAssertEqual(url2.absoluteString, "https://example.com/path?firstName=John&lastName=Doe")
    }
}
