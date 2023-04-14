//
// StringExtensionTests.swift
// Proton Pass - Created on 14/04/2023.
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

final class StringExtensionTests: XCTestCase {
    func testGenerateInitials() {
        XCTAssertEqual("John doe wick".initialsRemovingEmojis(), "JD")
        XCTAssertEqual("john doe wick".initialsRemovingEmojis(), "JD")
        XCTAssertEqual("john-doe wick".initialsRemovingEmojis(), "JW")
        XCTAssertEqual("   john wick doe".initialsRemovingEmojis(), "JW")
        XCTAssertEqual("😊john↑doe".initialsRemovingEmojis(), "JO")
        XCTAssertEqual("😊j😊ohndoe".initialsRemovingEmojis(), "JO")
        XCTAssertEqual("😊john 😊😊😊😊wick".initialsRemovingEmojis(), "JW")
        XCTAssertEqual("j".initialsRemovingEmojis(), "J")
        XCTAssertEqual("".initialsRemovingEmojis(), "")
    }
}
