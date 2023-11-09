//
// CreateUrlRequestTests.swift
// Proton Pass - Created on 09/11/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import Entities
import XCTest

final class CreateUrlRequestTests: XCTestCase {
    var sut: CreateUrlRequestUseCase!

    struct Person: Codable, Equatable {
        let name: String
        let age: Int
    }

    override func setUp() {
        super.setUp()
        sut = MakeUrlRequest()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testMakeRequestWithNoAccessTokenAndNoBody() throws {
        let request = try sut(baseUrl: "https://proton.me",
                              path: "api/v1/test",
                              method: .get,
                              appVersion: "pass-ios@1.0.0",
                              sessionId: "test_session_id",
                              accessToken: nil,
                              body: nil)

        XCTAssertEqual(request.url?.absoluteString, "https://proton.me/api/v1/test")
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.allHTTPHeaderFields?["X-Enforce-UnauthSession"], "true")
        XCTAssertEqual(request.allHTTPHeaderFields?["x-pm-appversion"], "pass-ios@1.0.0")
        XCTAssertEqual(request.allHTTPHeaderFields?["x-pm-uid"], "test_session_id")
        XCTAssertNil(request.httpBody)
    }

    func testMakeRequestWithAccessTokenAndBody() throws {
        let alice = Person(name: "Alice", age: 20)
        let request = try sut(baseUrl: "https://proton.me",
                              path: "api/v1/test",
                              method: .post,
                              appVersion: "pass-ios@1.0.0",
                              sessionId: "test_session_id",
                              accessToken: "test_access_token",
                              body: alice)

        XCTAssertEqual(request.url?.absoluteString, "https://proton.me/api/v1/test")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.allHTTPHeaderFields?["X-Enforce-UnauthSession"], "true")
        XCTAssertEqual(request.allHTTPHeaderFields?["x-pm-appversion"], "pass-ios@1.0.0")
        XCTAssertEqual(request.allHTTPHeaderFields?["x-pm-uid"], "test_session_id")
        XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer test_access_token")

        let body = try XCTUnwrap(request.httpBody)
        let person = try JSONDecoder().decode(Person.self, from: body)
        XCTAssertEqual(person, alice)
    }
}
