//
// URLExtensionTests.swift
// Proton Pass - Created on 18/01/2023.
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

@testable import Core
import XCTest

final class URLExtensionTests: XCTestCase {
    func testParamSubcript() throws {
        let url = try XCTUnwrap(URL(string: "https://example.com?param1=123&param2=abc"))
        XCTAssertEqual(url["param1"], "123")
        XCTAssertEqual(url["param2"], "abc")
        XCTAssertNil(url["param3"])
    }
}
