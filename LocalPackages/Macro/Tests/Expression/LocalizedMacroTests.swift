//
// LocalizedMacroTests.swift
// Proton Pass - Created on 25/09/2023.
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

@testable import MacroImplementation
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class LocalizedMacroTests: XCTestCase {
    private let macros = ["localized": LocalizedMacro.self]

    func testExpansionWithNumericLocalizedKey() {
        assertMacroExpansion("""
                             #localized(123)
                             """,
                             expandedSource: """
                             #localized(123)
                             """,
                             diagnostics: [
                                 .init(message: LocalizedMacroError.firstArgumentMustBeAString,
                                       line: 1,
                                       column: 1)
                             ],
                             macros: macros)
    }

    func testExpansionWithBooleanLocalizedKey() {
        assertMacroExpansion("""
                             #localized(true)
                             """,
                             expandedSource: """
                             #localized(true)
                             """,
                             diagnostics: [
                                 .init(message: LocalizedMacroError.firstArgumentMustBeAString,
                                       line: 1,
                                       column: 1)
                             ],
                             macros: macros)
    }

    func testExpansionWithNonStaticStringLocalizedKey() {
        assertMacroExpansion("""
                             #localized("Hello" + " " + "world")
                             """,
                             expandedSource: """
                             #localized("Hello" + " " + "world")
                             """,
                             diagnostics: [
                                 .init(message: LocalizedMacroError.firstArgumentMustBeAString,
                                       line: 1,
                                       column: 1)
                             ],
                             macros: macros)
    }

    func testExpansionWithEmptyStaticStringLocalizedKey() {
        assertMacroExpansion("""
                             #localized("")
                             """,
                             expandedSource: """
                             #localized("")
                             """,
                             diagnostics: [
                                 .init(message: LocalizedMacroError.emptyLocalizedKey, line: 1, column: 1)
                             ],
                             macros: macros)
    }

    func testExpansionWithNonEmptyStaticStringLocalizedKey() {
        assertMacroExpansion("""
                             #localized("Hello world")
                             """,
                             expandedSource: """
                             String(localized: "Hello world")
                             """,
                             macros: macros)
    }

    func testExpansionWithNonEmptyStaticStringLocalizedKeyAndOneArgument() {
        assertMacroExpansion("""
                             #localized("Hello %@", "world")
                             """,
                             expandedSource: """
                             String(format: String(localized: "Hello %@"), "world")
                             """,
                             macros: macros)
    }

    func testExpansionWithNonEmptyStaticStringLocalizedKeyAndTwoArguments() {
        assertMacroExpansion("""
                             #localized("Version %@ (%d)", "1.0.0", 5)
                             """,
                             expandedSource: """
                             String(format: String(localized: "Version %@ (%d)"), "1.0.0", 5)
                             """,
                             macros: macros)
    }

    func testExpansionWithNonEmptyStaticStringLocalizedKeyAndThreeArguments() {
        assertMacroExpansion("""
                             #localized("Version %@ (%d) (%@)", "1.0.0", 5, "abcd1234")
                             """,
                             expandedSource: """
                             String(format: String(localized: "Version %@ (%d) (%@)"), "1.0.0", 5, "abcd1234")
                             """,
                             macros: macros)
    }
}
