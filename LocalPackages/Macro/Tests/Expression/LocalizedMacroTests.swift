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

    func testExpansionWithFirstArgumentOtherThanString() {
        assertMacroExpansion("""
                             #localized(123)
                             """,
                             expandedSource: """
                             #localized(123)
                             """,
                             diagnostics: [
                                 .init(message: LocalizedMacroError.firstArgumentStaticStringLiteral, line: 1,
                                       column: 1)
                             ],
                             macros: macros)
    }

    func testExpansionWithEmptyLocalizedKey() {
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

    func testExpansionWithStaticStringArgument() {
        assertMacroExpansion("""
                             #localized("a string to localized")
                             """,
                             expandedSource: """
                             String(localized: "a string to localized")
                             """,
                             macros: macros)
    }
}
