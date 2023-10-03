//
// AliasPrefixValidatorTests.swift
// Proton Pass - Created on 21/11/2022.
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

@testable import Core
import XCTest

final class AliasPrefixValidatorTests: XCTestCase {
    func testPrefixValidation() {
        XCTAssertThrowsError(try AliasPrefixValidator.validate(prefix: "")) { error in
            XCTAssertEqual(error as? AliasPrefixError, .emptyPrefix)
        }

        XCTAssertThrowsError(try AliasPrefixValidator.validate(prefix: "abcDEF")) { error in
            XCTAssertEqual(error as? AliasPrefixError, .disallowedCharacters)
        }

        XCTAssertThrowsError(try AliasPrefixValidator.validate(prefix: "abc😊def")) { error in
            XCTAssertEqual(error as? AliasPrefixError, .disallowedCharacters)
        }

        XCTAssertThrowsError(try AliasPrefixValidator.validate(prefix: "café_au_lait")) { error in
            XCTAssertEqual(error as? AliasPrefixError, .disallowedCharacters)
        }

        XCTAssertThrowsError(try AliasPrefixValidator.validate(prefix: "abc'/")) { error in
            XCTAssertEqual(error as? AliasPrefixError, .disallowedCharacters)
        }

        XCTAssertThrowsError(try AliasPrefixValidator.validate(prefix: "abc..def")) { error in
            XCTAssertEqual(error as? AliasPrefixError, .twoConsecutiveDots)
        }

        XCTAssertThrowsError(try AliasPrefixValidator.validate(prefix: "abc.")) { error in
            XCTAssertEqual(error as? AliasPrefixError, .dotAtTheEnd)
        }

        XCTAssertNoThrow(try AliasPrefixValidator.validate(prefix: "abc.123"))
        XCTAssertNoThrow(try AliasPrefixValidator.validate(prefix: "abc.123_"))
        XCTAssertNoThrow(try AliasPrefixValidator.validate(prefix: "abc.123_-xyz"))
    }
}
