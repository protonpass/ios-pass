//
// CodableBase64Tests.swift
// Proton Pass - Created on 28/09/2022.
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

@testable import Entities
import XCTest

final class CodableBase64Tests: XCTestCase {
    struct Person: CodableBase64 {
        let name: String
        let age: Int
    }

    func testSerializeBase64() throws {
        // Given
        let johnDoe = Person(name: "John Doe", age: 31)

        // When
        let base64String = try johnDoe.serializeBase64()

        // Then
        // iOS 17 fix: serialization process doesn't respect property order
        // so we compare against 2 possible base 64 strings
        XCTAssertTrue(["eyJhZ2UiOjMxLCJuYW1lIjoiSm9obiBEb2UifQ==",
                       "eyJuYW1lIjoiSm9obiBEb2UiLCJhZ2UiOjMxfQ=="].contains(base64String))
    }

    func testDeserializeBase64() throws {
        // Given
        let base64String = "eyJuYW1lIjoiSm9obiBEb2UiLCJhZ2UiOjMxfQ=="

        // When
        let person = try Person.deserializeBase64(base64String)

        // Then
        XCTAssertEqual(person.name, "John Doe")
        XCTAssertEqual(person.age, 31)
    }
}
