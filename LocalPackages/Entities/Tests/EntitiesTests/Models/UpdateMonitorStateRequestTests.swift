//
// UpdateMonitorStateRequestTests.swift
// Proton Pass - Created on 22/04/2024.
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
import XCTest

final class UpdateMonitorStateRequestTests: XCTestCase {
    func testEncode() throws {
        try XCTAssertEqual("{\"ProtonAddress\":true}", encoded(.protonAddress(true)))
        try XCTAssertEqual("{\"ProtonAddress\":false}", encoded(.protonAddress(false)))
        try XCTAssertEqual("{\"Aliases\":true}", encoded(.aliases(true)))
        try XCTAssertEqual("{\"Aliases\":false}", encoded(.aliases(false)))
    }

    func encoded(_ request: UpdateMonitorStateRequest) throws -> String {
        let data = try JSONEncoder().encode(request)
        return String(data: data, encoding: .utf8) ?? ""
    }
}
