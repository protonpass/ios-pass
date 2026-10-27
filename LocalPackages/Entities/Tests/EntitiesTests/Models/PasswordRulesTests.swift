//
// PasswordRulesTests.swift
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

@testable import Entities
import Testing

@Suite(.tags(.entity))
struct PasswordRulesTests {
    private let upper = PasswordRules.CharacterClass.upper.characters
    private let lower = PasswordRules.CharacterClass.lower.characters
    private let digit = PasswordRules.CharacterClass.digit.characters
    private let special = PasswordRules.CharacterClass.special.characters
    private let asciiPrintable = PasswordRules.CharacterClass.asciiPrintable.characters

    // MARK: - Parsing

    @Test func `length and consecutive limits are parsed with everything allowed`() throws {
        let rules = try #require(PasswordRules("minlength: 8; maxlength: 16; max-consecutive: 2;"))

        #expect(rules == PasswordRules(allowed: asciiPrintable,
                                       minLength: 8,
                                       maxLength: 16,
                                       maxConsecutive: 2))
    }

    @Test func `required characters are also the allowed ones when nothing else is allowed`() throws {
        let rules = try #require(PasswordRules("required: upper; required: digit"))

        #expect(rules.requiredSets == [upper, digit])
        #expect(rules.allowed == upper.union(digit))
    }

    @Test func `named classes are case insensitive and combine within one property`() throws {
        let rules = try #require(PasswordRules("required: UPPER, Digit"))

        #expect(rules.requiredSets == [upper.union(digit)])
    }

    @Test func `unicode is narrowed to ascii printable`() throws {
        let rules = try #require(PasswordRules("allowed: unicode"))

        #expect(rules.allowed == asciiPrintable)
    }

    @Test func `a custom class keeps separators and a closing literal bracket`() throws {
        let rules = try #require(PasswordRules(
            "minlength: 8; required: digit; required: [- !\"#$&'()*+,.:;<=>?@[^_`{|}~]]; allowed: lower, upper;"
        ))

        #expect(rules.minLength == 8)
        #expect(rules.requiredSets == [digit, Set("- !\"#$&'()*+,.:;<=>?@[^_`{|}~]")])
        #expect(rules.allowed == digit.union(lower).union(upper).union(rules.requiredSets[1]))
    }

    @Test func `a dash after the first position of a custom class is ignored`() throws {
        let rules = try #require(PasswordRules("allowed: [a-z]"))

        #expect(rules.allowed == ["a", "z"])
    }

    @Test func `repeated limits keep the strictest value`() throws {
        let rules = try #require(PasswordRules(
            "minlength: 8; minlength: 12; maxlength: 20; maxlength: 16; max-consecutive: 3; max-consecutive: 2"
        ))

        #expect(rules.minLength == 12)
        #expect(rules.maxLength == 16)
        #expect(rules.maxConsecutive == 2)
    }

    @Test func `repeating and sequential limits are accepted but not enforced`() throws {
        let rules = try #require(PasswordRules("minlength: 8; max-repeating: 2; max-sequential: 3"))

        #expect(rules == PasswordRules(minLength: 8))
    }

    @Test func `empty properties and zero values are skipped`() throws {
        let rules = try #require(PasswordRules("required: ;; minlength: 0; maxlength: 12;"))

        #expect(rules == PasswordRules(maxLength: 12))
    }

    @Test(arguments: ["",
                      "   ",
                      "minlength: 0",
                      "max-repeating: 3",
                      "minlength",
                      "minlength 8",
                      "foo: 3",
                      "required: emoji",
                      "required: upper,",
                      "required: 123",
                      "allowed: [abc",
                      "minlength: 8 maxlength: 9",
                      "minlength: 99999999999999999999999999",
                      "Minlength: 8"])
    func `a malformed or empty string has no rules`(rules: String) {
        #expect(PasswordRules(rules) == nil)
    }

    // MARK: - Apple's quirks

    @Test(arguments: Self.quirks)
    func `a real site's rules parse into exactly what they declare`(rules: String,
                                                                    expected: PasswordRules) {
        #expect(PasswordRules(rules) == expected)
    }

    // MARK: - Source precedence

    @Test func `the quirks take precedence over the password fields`() {
        let rules = PasswordRules(quirks: "maxlength: 10",
                                  passwordField: "maxlength: 20",
                                  confirmPasswordField: "maxlength: 30")

        #expect(rules?.maxLength == 10)
    }

    @Test func `an unusable source falls through to the next one`() {
        #expect(PasswordRules(quirks: "foo: 1",
                              passwordField: "maxlength: 20",
                              confirmPasswordField: "maxlength: 30")?.maxLength == 20)
        #expect(PasswordRules(quirks: nil,
                              passwordField: nil,
                              confirmPasswordField: "maxlength: 30")?.maxLength == 30)
        #expect(PasswordRules(quirks: nil, passwordField: "", confirmPasswordField: nil) == nil)
    }

    // MARK: - Satisfaction

    @Test(arguments: [("abc123", true),
                      ("aab123", true),
                      ("abc12", false),
                      ("abcdefgh123", false),
                      ("abcdef", false),
                      ("abcDE1", false),
                      ("aaab12", false)])
    func `a password is checked against every rule`(password: String, expected: Bool) throws {
        let rules = try #require(PasswordRules(
            "minlength: 6; maxlength: 10; required: digit; allowed: lower; max-consecutive: 2"
        ))

        #expect(rules.isSatisfied(by: password) == expected)
    }

    // MARK: - Organization policy

    @Test func `policy flags require, forbid or leave a class unconstrained`() {
        let rules = PasswordRules(randomPasswordPolicy: policy(minLength: 10,
                                                               maxLength: 30,
                                                               numbers: true,
                                                               uppercase: false,
                                                               symbols: nil))

        #expect(rules.requiredSets == [digit])
        #expect(rules.allowed == asciiPrintable.subtracting(upper))
        #expect(rules.minLength == 10)
        #expect(rules.maxLength == 30)
    }

    // MARK: - Intersection

    @Test func `compatible rules are narrowed to what satisfies both`() throws {
        let site = try #require(PasswordRules("minlength: 8; maxlength: 16; allowed: lower, digit, [-_]"))
        let organization = PasswordRules(randomPasswordPolicy: policy(minLength: 4, maxLength: 64, numbers: true))

        let rules = try #require(site.intersected(with: organization))

        #expect(rules.minLength == 8)
        #expect(rules.maxLength == 16)
        #expect(rules.requiredSets == [digit])
        #expect(rules.allowed == lower.union(digit).union(["-", "_"]))
    }

    @Test func `a required class that the other rules forbid makes them incompatible`() throws {
        let site = try #require(PasswordRules("required: [!@#]"))
        let organization = PasswordRules(randomPasswordPolicy: policy(symbols: false))

        #expect(site.intersected(with: organization) == nil)
    }

    @Test func `non-overlapping lengths make rules incompatible`() throws {
        let site = try #require(PasswordRules("maxlength: 12"))
        let organization = PasswordRules(randomPasswordPolicy: policy(minLength: 20))

        #expect(site.intersected(with: organization) == nil)
    }

    @Test func `more required classes than the maximum length makes rules incompatible`() throws {
        let site = try #require(PasswordRules("maxlength: 2; required: upper; required: lower; required: digit"))

        #expect(site.intersected(with: PasswordRules()) == nil)
    }

    @Test func `the special class covers ascii punctuation and space`() {
        #expect(special.count == 33)
        #expect(special.contains(" "))
        #expect(special.isDisjoint(with: upper.union(lower).union(digit)))
        #expect(asciiPrintable.count == 95)
    }
}

private extension PasswordRulesTests {
    func policy(minLength: Int = 4,
                maxLength: Int = 64,
                numbers: Bool? = nil,
                uppercase: Bool? = nil,
                symbols: Bool? = nil) -> PasswordPolicy {
        PasswordPolicy(randomPasswordAllowed: true,
                       randomPasswordMinLength: minLength,
                       randomPasswordMaxLength: maxLength,
                       randomPasswordMustIncludeNumbers: numbers,
                       randomPasswordMustIncludeSymbols: symbols,
                       randomPasswordMustIncludeUppercase: uppercase,
                       memorablePasswordAllowed: true,
                       memorablePasswordMinWords: nil,
                       memorablePasswordMaxWords: nil,
                       memorablePasswordMustCapitalize: nil,
                       memorablePasswordMustIncludeNumbers: nil)
    }
}

private extension PasswordRulesTests {
    /// From https://github.com/apple/password-manager-resources/blob/main/quirks/password-rules.json
    static let quirks: [(String, PasswordRules)] = [
        // walmart.com
        (#"allowed: lower, upper, digit, [-(~!@#$%^&*_+=`|(){}[:;"'<>,.?]];"#,
         PasswordRules(allowed: .alphanumeric.union(#"-(~!@#$%^&*_+=`|(){}[:;"'<>,.?]"#))),
        // google.com
        (##"minlength: 8; allowed: lower, upper, digit, [-!"#$%&'()*+,./:;<=>?@[^_{|}~]];"##,
         PasswordRules(allowed: .alphanumeric.union(##"-!"#$%&'()*+,./:;<=>?@[^_{|}~]"##),
                       minLength: 8)),
        // verizonwireless.com
        ("minlength: 8; maxlength: 20; required: lower, upper; required: digit; allowed: unicode;",
         PasswordRules(requiredSets: [Set.lower.union(Set.upper), .digit],
                       allowed: .asciiPrintable,
                       minLength: 8,
                       maxLength: 20)),
        // aeon.co.jp
        ("minlength: 8; maxlength: 8; max-consecutive: 3; required: digit; required: upper,lower,[#$+./:=?@[^_|~]];",
         PasswordRules(requiredSets: [.digit, Set.upper.union(Set.lower).union("#$+./:=?@[^_|~]")],
                       allowed: .alphanumeric.union("#$+./:=?@[^_|~]"),
                       minLength: 8,
                       maxLength: 8,
                       maxConsecutive: 3)),
        // posteo.de, whose `’` is dropped for not being ASCII
        (#"minlength: 8; required: lower; required: upper; required: digit, [-~!#$%&_+=|(){}[:;"’<>,.? ]];"#,
         PasswordRules(requiredSets: [.lower, .upper, Set.digit.union(#"-~!#$%&_+=|(){}[:;"<>,.? ]"#)],
                       allowed: .alphanumeric.union(#"-~!#$%&_+=|(){}[:;"<>,.? ]"#),
                       minLength: 8)),
        // walgreens.com
        ("minlength: 8; required: lower; required: digit; allowed: [!#$%&*@^]",
         PasswordRules(requiredSets: [.lower, .digit],
                       allowed: Set.lower.union(Set.digit).union("!#$%&*@^"),
                       minLength: 8)),
        // vivo.com.br
        ("maxlength: 6; max-consecutive: 3; allowed: digit;",
         PasswordRules(allowed: .digit, maxLength: 6, maxConsecutive: 3)),
        // extraspace.com
        ("minlength: 8; maxlength: 20; allowed: lower; required: upper, digit, [!#$%&*?@];",
         PasswordRules(requiredSets: [Set.upper.union(Set.digit).union("!#$%&*?@")],
                       allowed: .alphanumeric.union("!#$%&*?@"),
                       minLength: 8,
                       maxLength: 20)),
        // zdf.de
        ("minlength: 8; required: upper; required: digit; allowed: lower, special;",
         PasswordRules(requiredSets: [.upper, .digit],
                       allowed: .alphanumeric.union(Set.special),
                       minLength: 8)),
        // amnh.org
        ("minlength: 8; maxlength: 16; required: digit; required: upper,lower; allowed: ascii-printable;",
         PasswordRules(requiredSets: [.digit, Set.upper.union(Set.lower)],
                       allowed: .asciiPrintable,
                       minLength: 8,
                       maxLength: 16)),
        // samsung.com
        ("max-consecutive: 2; required: lower, upper; required: digit; required: special;",
         PasswordRules(requiredSets: [Set.lower.union(Set.upper), .digit, .special],
                       allowed: .asciiPrintable,
                       maxConsecutive: 2)),
        // capitalone.com
        (#"minlength: 8; maxlength: 32; required: lower, upper; required: digit; allowed: [-_./\@$*&!#];"#,
         PasswordRules(requiredSets: [Set.lower.union(Set.upper), .digit],
                       allowed: .alphanumeric.union(#"-_./\@$*&!#"#),
                       minLength: 8,
                       maxLength: 32)),
        // kundenportal.edeka-smart.de, whose `§` is dropped for not being ASCII
        (#"minlength: 8; maxlength: 16; required: digit; required: upper, lower; required: [!"§$%&#];"#,
         PasswordRules(requiredSets: [.digit, Set.upper.union(Set.lower), Set(#"!"$%&#"#)],
                       allowed: .alphanumeric.union(#"!"$%&#"#),
                       minLength: 8,
                       maxLength: 16)),
        // twitter.com
        ("minlength: 8;", PasswordRules(minLength: 8)),
        // bhphotovideo.com
        ("maxlength: 15;", PasswordRules(maxLength: 15)),
        // ototoy.jp
        ("minlength: 8; allowed: upper,lower,digit,[- .=_];",
         PasswordRules(allowed: .alphanumeric.union("- .=_"), minLength: 8))
    ]
}

private extension Set<Character> {
    static var upper: Self { PasswordRules.CharacterClass.upper.characters }
    static var lower: Self { PasswordRules.CharacterClass.lower.characters }
    static var digit: Self { PasswordRules.CharacterClass.digit.characters }
    static var special: Self { PasswordRules.CharacterClass.special.characters }
    static var alphanumeric: Self { upper.union(lower).union(digit) }
    static var asciiPrintable: Self { PasswordRules.CharacterClass.asciiPrintable.characters }
}
