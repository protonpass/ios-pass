//
// EndpointTests.swift
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

final class EndpointTests: XCTestCase {
    func testGeneratePathCorrectly() throws {
        struct DummyEndpoint: Endpoint {
            struct Response: Codable {}

            let request: URLRequest

            init(url: URL) {
                self.request = .init(url: url)
            }
        }

        let url1 = try XCTUnwrap(URL(string: "https://example.com"))
        let endpoint1 = DummyEndpoint(url: url1)
        XCTAssertEqual(endpoint1.path, "")

        let url2 = try XCTUnwrap(URL(string: "https://example.com/path/to/something"))
        let endpoint2 = DummyEndpoint(url: url2)
        XCTAssertEqual(endpoint2.path, "/path/to/something")

        let url3 = try XCTUnwrap(URL(string: "https://example.com/path?firstName=John&lastName=Doe"))
        let endpoint3 = DummyEndpoint(url: url3)
        XCTAssertEqual(endpoint3.path, "/path?firstName=John&lastName=Doe")
    }
}
