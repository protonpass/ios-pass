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
        XCTAssertEqual("John doe wick".initials(), "JD")
        XCTAssertEqual("john doe wick".initials(), "JD")
        XCTAssertEqual("john-doe wick".initials(), "JW")
        XCTAssertEqual("   john wick doe".initials(), "JW")
        XCTAssertEqual("john↑doe".initials(), "JO")
        XCTAssertEqual("johndoe".initials(), "JO")
        XCTAssertEqual("john wick".initials(), "JW")
        XCTAssertEqual("j".initials(), "J")
        XCTAssertEqual("".initials(), "")
        XCTAssertEqual("012".initials(), "01")
    }

    func testCharacterCount() {
        XCTAssertEqual("teststring".characterCount("t"), 3)
        XCTAssertEqual("test long string".characterCount(" "), 2)
        XCTAssertEqual("🤘 string with emoji 😊😊 and special character (◕‿◕)".characterCount("😊"), 2)
    }

    func testConvertToCardNumber() {
        XCTAssertEqual("341234569865".toCreditCardNumber(),
                       "3412 345698 65")
        XCTAssertEqual("341234569865857".toCreditCardNumber(),
                       "3412 345698 65857")
        XCTAssertEqual("3712345698658579".toCreditCardNumber(),
                       "3712 3456 9865 8579")
        XCTAssertEqual("671934946329032".toCreditCardNumber(),
                       "6719 3494 6329 032")
    }

    func testConvertToMaskedCardNumber() {
        XCTAssertEqual("341234569865".toMaskedCreditCardNumber(),
                       "3412 •••• 9865")
        XCTAssertEqual("341234569865857".toMaskedCreditCardNumber(),
                       "3412 •••••• 65857")
        XCTAssertEqual("3712345698658579".toMaskedCreditCardNumber(),
                       "3712 •••• •••• 8579")
        XCTAssertEqual("671934946329032".toMaskedCreditCardNumber(),
                       "6719 •••• •••• 032")
        XCTAssertEqual("67193494632903247021".toMaskedCreditCardNumber(),
                       "6719 •••• •••• •••• 7021")
    }
}
