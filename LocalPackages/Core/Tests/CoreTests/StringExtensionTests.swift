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
import Testing
import Foundation

@Suite("String extensions")
struct StringExtensionTests {

    @Test(arguments: [
        ("John doe wick", "JD"),
        ("john doe wick", "JD"),
        ("john-doe wick", "JW"),
        ("   john wick doe", "JW"),
        ("john↑doe", "JO"),     // ↑ is not a separator → single word, first two chars
        ("johndoe", "JO"),
        ("john wick", "JW"),
        ("j", "J"),
        ("", ""),
        ("012", "01"),
    ])
    func `initials`(input: String, expected: String) {
        #expect(input.initials() == expected)
    }

    @Test(arguments: [
        ("teststring", Character("t"), 3),
        ("test long string", Character(" "), 2),
        ("🤘 string with emoji 😊😊 and special character (◕‿◕)", Character("😊"), 2),
    ])
    func `characterCount`(input: String, needle: Character, expected: Int) {
        #expect(input.characterCount(needle) == expected)
    }

    @Test(arguments: [
        ("341234569865", "3412 345698 65"),
        ("341234569865857", "3412 345698 65857"),
        ("3712345698658579", "3712 3456 9865 8579"),
        ("671934946329032", "6719 3494 6329 032"),
    ])
    func `toCreditCardNumber`(input: String, expected: String) {
        #expect(input.toCreditCardNumber() == expected)
    }

    @Test(arguments: [
        ("341234569865", "3412 •••• 9865"),
        ("341234569865857", "3412 •••••• 65857"),
        ("3712345698658579", "3712 •••• •••• 8579"),
        ("671934946329032", "6719 •••• •••• 032"),
        ("67193494632903247021", "6719 •••• •••• •••• 7021"),
    ])
    func `toMaskedCreditCardNumber`(input: String, expected: String) {
        #expect(input.toMaskedCreditCardNumber() == expected)
    }

    @Test(arguments: [
        ("ABBBB", "AzzzB"),
        ("AB", "AB"),
    ])
    func `replaceAllCharsExceptFirstAndLast`(input: String, expected: String) {
        #expect(input.replaceAllCharsExceptFirstAndLast(withChar: "z") == expected)
    }
}
