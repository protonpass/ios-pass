//
// GenerateRuleCompliantPasswordTests.swift
// Proton Pass - Created on 14/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Entities
import Testing
import UseCases

@Suite(.tags(.useCase))
struct GenerateRuleCompliantPasswordTests {
    private let sut = GenerateRuleCompliantPassword()

    @Test(arguments: [
        "minlength: 8; required: digit; required: [- !\"#$&'()*+,.:;<=>?@[^_`{|}~]]; allowed: lower, upper;",
        "minlength: 8; maxlength: 20; max-consecutive: 2; required: lower, upper; required: digit;",
        "minlength: 8; maxlength: 16; required: upper; required: [!#$%&*@^]; allowed: lower, digit;",
        "minlength: 6; maxlength: 6; allowed: digit; max-consecutive: 2",
        "allowed: [ ab]; minlength: 12"
    ])
    func `every generated password satisfies the rules and has no space`(rawRules: String) throws {
        let rules = try #require(PasswordRules(rawRules))

        for _ in 0..<200 {
            let password = try #require(sut(rules: rules, preferredLength: 20))
            #expect(rules.isSatisfied(by: password))
            #expect(!password.contains(" "))
        }
    }

    @Test(arguments: [
        ("minlength: 8; maxlength: 16", 20, 16),
        ("minlength: 8; maxlength: 16", 4, 8),
        ("minlength: 8; maxlength: 16", 12, 12),
        ("minlength: 30", 20, 30),
        ("allowed: lower", 20, 20)
    ])
    func `the preferred length is clamped into the rule bounds`(rawRules: String,
                                                                preferredLength: Int,
                                                                expectedLength: Int) throws {
        let rules = try #require(PasswordRules(rawRules))

        let password = try #require(sut(rules: rules, preferredLength: preferredLength))

        #expect(password.count == expectedLength)
    }

    @Test func `lowercase, uppercase and digits are included whenever the rules allow them`() throws {
        let rules = try #require(PasswordRules("allowed: ascii-printable"))
        let classes: [PasswordRules.CharacterClass] = [.lower, .upper, .digit]

        for _ in 0..<200 {
            let password = try #require(sut(rules: rules, preferredLength: 20))
            for characterClass in classes {
                #expect(!characterClass.characters.isDisjoint(with: password))
            }
        }
    }

    @Test(arguments: [
        "required: [ ]",
        "allowed: [ ]",
        "allowed: [a]; minlength: 2; max-consecutive: 1"
    ])
    func `unsatisfiable rules generate nothing`(rawRules: String) throws {
        let rules = try #require(PasswordRules(rawRules))

        #expect(sut(rules: rules, preferredLength: 20) == nil)
    }
}
