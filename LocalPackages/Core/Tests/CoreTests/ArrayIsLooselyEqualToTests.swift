//
// ArrayIsLooselyEqualToTests.swift
// Proton Pass - Created on 30/08/2023.
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
import Foundation
import Testing

@Suite(.tags(.utilities))
struct ArrayIsLooselyEqualToTests {
    private struct Person: Identifiable, Equatable {
        var id = UUID().uuidString
        var name = String.random()
    }

    @Test func `arrays are loosely equal when they hold the same elements in any order`() {
        let alice = Person()
        let bob = Person()
        let charlie = Person()

        #expect([alice, bob, charlie].isLooselyEqual(to: [bob, charlie, alice]))
        #expect([alice, charlie, bob].isLooselyEqual(to: [charlie, alice, bob]))
        #expect([alice, bob, charlie].isLooselyEqual(to: [alice, bob, charlie]))
        #expect(![alice, bob, charlie].isLooselyEqual(to: [alice, bob]))
        #expect(![bob, charlie].isLooselyEqual(to: [alice, bob, charlie]))
    }
}
