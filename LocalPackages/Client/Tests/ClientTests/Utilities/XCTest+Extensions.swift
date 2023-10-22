//
// XCTest+Extensions.swift
// Proton Pass - Created on 20/06/2023.
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

import XCTest

extension XCTestCase {
    func XCTUnwrapAsync<T>(_ operation: @autoclosure () async throws -> T?) async throws -> T {
        let object = try await operation()
        return try XCTUnwrap(object)
    }

    func assertEncodeCorrectly<T: Encodable>(_ object: T, _ expectedResult: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let json = try JSONSerialization.jsonObject(with: encoder.encode(object))
        let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let result = String(data: data, encoding: .utf8)
        XCTAssertEqual(result, expectedResult)
    }
}
