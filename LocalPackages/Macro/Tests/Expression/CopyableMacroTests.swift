//
// CopyableMacroTests.swift
// Proton Pass - Created on 12/10/2023.
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
import Macro
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

let testMacros: [String: Macro.Type] = [
    "Copyable": CopyableMacro.self
]

@Copyable
struct Person: Equatable {
    var name: String

    let age: Int

    /// This should not generate a copy function because it's not a stored property.
    var fullName: String {
        get {
            name
        }
        set {
            name = newValue
        }
    }

    /// This should not generate a copy function because it's not a stored property.
    var uppercasedName: String {
        name.uppercased()
    }

    var nickName: String? = "Bobby Tables" {
        didSet {
            print("nickName changed to \(nickName ?? "(nil)")")
        }
    }
}

final class CopyableMacroTests: XCTestCase {
    func testMacroExpansion() {
        assertMacroExpansion(#"""
                             @Copyable
                             struct Person {
                                 var name: String
                                 let age: Int
                                 var fullName: String {
                                     get {
                                         name
                                     }
                                     set {
                                         name = newValue
                                     }
                                 }
                                 var uppercasedName: String {
                                     name.uppercased()
                                 }
                                 var nickName: String? = "Bobby Tables" {
                                     didSet {
                                         print("nickName changed to \(nickName ?? "(nil)")")
                                     }
                                 }
                             }
                             """#,
                             expandedSource: #"""
                             struct Person {
                                 var name: String
                                 let age: Int
                                 var fullName: String {
                                     get {
                                         name
                                     }
                                     set {
                                         name = newValue
                                     }
                                 }
                                 var uppercasedName: String {
                                     name.uppercased()
                                 }
                                 var nickName: String? = "Bobby Tables" {
                                     didSet {
                                         print("nickName changed to \(nickName ?? "(nil)")")
                                     }
                                 }

                                 /// Returns a copy of the caller whose value for `name` is different.
                                 func copy(name: String) -> Self {
                                     .init(name: name, age: age, nickName: nickName)
                                 }

                                 /// Returns a copy of the caller whose value for `age` is different.
                                 func copy(age: Int) -> Self {
                                     .init(name: name, age: age, nickName: nickName)
                                 }

                                 /// Returns a copy of the caller whose value for `nickName` is different.
                                 func copy(nickName: String?) -> Self {
                                     .init(name: name, age: age, nickName: nickName)
                                 }
                             }
                             """#,
                             macros: testMacros)
    }

    func testNewLetValue() {
        let person = Person(name: "Walter White", age: 50, nickName: "Heisenberg")
        let copiedPerson = person.copy(age: 51)
        XCTAssertEqual(Person(name: "Walter White", age: 51, nickName: "Heisenberg"), copiedPerson)
    }

    func testNewVarValue() {
        let person = Person(name: "Walter White", age: 50, nickName: "Heisenberg")
        let copiedPerson = person.copy(name: "W.W.")
        XCTAssertEqual(Person(name: "W.W.", age: 50, nickName: "Heisenberg"), copiedPerson)
    }

    func testNewOptionalValue() {
        let person = Person(name: "Walter White", age: 50, nickName: "Heisenberg")
        let copiedPerson = person.copy(nickName: nil)
        XCTAssertEqual(Person(name: "Walter White", age: 50, nickName: nil), copiedPerson)
    }

    func testChainedNewValues() {
        let person = Person(name: "Walter White", age: 50, nickName: "Heisenberg")
        let copiedPerson = person.copy(name: "Skyler White").copy(age: 48)
        XCTAssertEqual(Person(name: "Skyler White", age: 48, nickName: "Heisenberg"), copiedPerson)
    }
}
