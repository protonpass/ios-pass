//
// Data+RandomTests.swift
// Proton Pass - Created on 19/04/2023.
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

final class DataPlusRandomTests: XCTestCase {
    func testRandomData() throws {
        // Given
        let givenByteCount = Int.random(in: 100...1_000)

        // When
        let randomData = try Data.random(byteCount: givenByteCount)

        // Then
        XCTAssertEqual(randomData.count, givenByteCount)
    }
}
