//
// PasswordRules.swift
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

import Foundation

/// Apple's password rules language (https://developer.apple.com/password-rules/), as declared by the
/// `passwordrules` HTML attribute, `UITextInputPasswordRules` and Apple's password-manager-resources quirks.
public struct PasswordRules: Sendable, Equatable {
    /// A password must contain at least one character of each set.
    public let requiredSets: [Set<Character>]
    /// Always includes every required character.
    public let allowed: Set<Character>
    public let minLength: Int?
    public let maxLength: Int?
    /// Longest allowed run of the same character.
    public let maxConsecutive: Int?

    public init(requiredSets: [Set<Character>] = [],
                allowed: Set<Character> = CharacterClass.asciiPrintable.characters,
                minLength: Int? = nil,
                maxLength: Int? = nil,
                maxConsecutive: Int? = nil) {
        self.requiredSets = requiredSets
        self.allowed = allowed
        self.minLength = minLength
        self.maxLength = maxLength
        self.maxConsecutive = maxConsecutive
    }
}

public extension PasswordRules {
    enum CharacterClass: String, Sendable {
        case upper, lower, digit, special
        case asciiPrintable = "ascii-printable"

        public var characters: Set<Character> {
            switch self {
            case .upper: .ascii(0x41...0x5A)
            case .lower: .ascii(0x61...0x7A)
            case .digit: .ascii(0x30...0x39)
            case .special: .ascii(0x20...0x2F, 0x3A...0x40, 0x5B...0x60, 0x7B...0x7E)
            case .asciiPrintable: .ascii(0x20...0x7E)
            }
        }
    }

    /// Mirrors Apple's reference parser (password-manager-resources `PasswordRulesParser.js`), except that a
    /// syntax error anywhere rejects the whole string instead of keeping the properties parsed before it.
    /// Returns `nil` on a syntax error or when no rule is declared.
    init?(_ rules: String) {
        var scanner = Scanner(rules)
        var builder = Builder()

        scanner.skipWhitespace()
        while !scanner.isAtEnd {
            if scanner.consume(";") {
                scanner.skipWhitespace()
                continue
            }
            guard let property = Property(rawValue: scanner.identifier()),
                  scanner.consume(":"),
                  builder.parseValue(of: property, from: &scanner) else {
                return nil
            }

            scanner.skipWhitespace()
            if scanner.isAtEnd {
                break
            }
            guard scanner.consume(";") else { return nil }
            scanner.skipWhitespace()
        }

        guard let rules = builder.rules else { return nil }
        self = rules
    }

    /// Picks the first source that parses. Apple only keeps a domain in its quirks list while the site's own
    /// rules are missing or inaccurate, so the quirks win over the page's rules.
    init?(quirks: String?, passwordField: String?, confirmPasswordField: String?) {
        guard let rules = [quirks, passwordField, confirmPasswordField]
            .lazy
            .compactMap({ $0.flatMap { PasswordRules($0) } })
            .first else { return nil }
        self = rules
    }

    /// Constraints an organization's password policy puts on random passwords. A `false` "must include" flag
    /// forbids the class, matching the in-app generator which locks the option off.
    init(randomPasswordPolicy policy: PasswordPolicy) {
        var requiredSets = [Set<Character>]()
        var allowed = CharacterClass.asciiPrintable.characters
        let flags = [
            (policy.randomPasswordMustIncludeNumbers, CharacterClass.digit),
            (policy.randomPasswordMustIncludeUppercase, CharacterClass.upper),
            (policy.randomPasswordMustIncludeSymbols, CharacterClass.special)
        ]
        for (mustInclude, characterClass) in flags {
            switch mustInclude {
            case true?: requiredSets.append(characterClass.characters)
            case false?: allowed.subtract(characterClass.characters)
            case nil: break
            }
        }
        self.init(requiredSets: requiredSets,
                  allowed: allowed,
                  minLength: policy.randomPasswordMinLength,
                  maxLength: policy.randomPasswordMaxLength)
    }

    /// Rules a password must meet to satisfy both `self` and `other`, or `nil` when no password can.
    func intersected(with other: PasswordRules) -> PasswordRules? {
        let allowed = allowed.intersection(other.allowed)
        let requiredSets = (requiredSets + other.requiredSets).map { $0.intersection(allowed) }
        let minLength = [minLength, other.minLength].compactMap(\.self).max()
        let maxLength = [maxLength, other.maxLength].compactMap(\.self).min()
        let maxConsecutive = [maxConsecutive, other.maxConsecutive].compactMap(\.self).min()

        guard !allowed.isEmpty, !requiredSets.contains(where: \.isEmpty) else { return nil }
        if let maxLength, maxLength < max(minLength ?? 0, requiredSets.count) {
            return nil
        }

        return PasswordRules(requiredSets: requiredSets,
                             allowed: allowed,
                             minLength: minLength,
                             maxLength: maxLength,
                             maxConsecutive: maxConsecutive)
    }

    func isSatisfied(by password: String) -> Bool {
        let characters = Array(password)
        if let minLength, characters.count < minLength {
            return false
        }
        if let maxLength, characters.count > maxLength {
            return false
        }
        if let maxConsecutive, characters.longestRunLength > maxConsecutive {
            return false
        }
        return characters.allSatisfy(allowed.contains)
            && requiredSets.allSatisfy { !$0.isDisjoint(with: characters) }
    }
}

private enum Property: String {
    case required, allowed
    case minLength = "minlength"
    case maxLength = "maxlength"
    case maxConsecutive = "max-consecutive"
    // Undocumented and unused by Apple's quirks list, so parsed for validity but not enforced
    case maxRepeating = "max-repeating"
    case maxSequential = "max-sequential"
}

private struct Builder {
    private var requiredSets = [Set<Character>]()
    private var allowed = Set<Character>()
    private var minLength: Int?
    private var maxLength: Int?
    private var maxConsecutive: Int?

    var rules: PasswordRules? {
        if requiredSets.isEmpty, allowed.isEmpty, minLength == nil, maxLength == nil, maxConsecutive == nil {
            return nil
        }
        let defaultAllowed = PasswordRules.CharacterClass.asciiPrintable.characters
        return PasswordRules(requiredSets: requiredSets,
                             allowed: allowed.isEmpty ? defaultAllowed : allowed,
                             minLength: minLength,
                             maxLength: maxLength,
                             maxConsecutive: maxConsecutive)
    }

    /// `false` on a syntax error. An empty value is valid and sets nothing.
    mutating func parseValue(of property: Property, from scanner: inout Scanner) -> Bool {
        scanner.skipWhitespace()
        guard !scanner.isAtPropertyEnd else { return true }

        switch property {
        case .allowed, .required:
            guard let characters = scanner.characterClasses() else { return false }
            allowed.formUnion(characters)
            if property == .required, !characters.isEmpty {
                requiredSets.append(characters)
            }

        case .maxConsecutive, .maxLength, .maxRepeating, .maxSequential, .minLength:
            guard let value = scanner.integer() else { return false }
            // Like the reference parser, a zero value sets no constraint
            if value > 0 {
                apply(limit: value, to: property)
            }
        }
        return true
    }

    private mutating func apply(limit: Int, to property: Property) {
        switch property {
        case .minLength: minLength = max(minLength ?? limit, limit)
        case .maxLength: maxLength = min(maxLength ?? limit, limit)
        case .maxConsecutive: maxConsecutive = min(maxConsecutive ?? limit, limit)
        case .allowed, .maxRepeating, .maxSequential, .required: break
        }
    }
}

private struct Scanner {
    private let characters: [Character]
    private var index = 0

    init(_ string: String) {
        characters = Array(string)
    }

    var isAtEnd: Bool {
        index >= characters.count
    }

    var isAtPropertyEnd: Bool {
        isAtEnd || current == ";"
    }

    private var current: Character? {
        isAtEnd ? nil : characters[index]
    }

    mutating func skipWhitespace() {
        while let current, current.isRulesWhitespace {
            index += 1
        }
    }

    mutating func consume(_ character: Character) -> Bool {
        guard current == character else { return false }
        index += 1
        return true
    }

    mutating func identifier() -> String {
        let start = index
        while let current, current.isIdentifierCharacter {
            index += 1
        }
        return String(characters[start..<index])
    }

    /// `nil` when there is no digit or the value overflows, since the input comes from untrusted web pages.
    mutating func integer() -> Int? {
        var value: Int?
        while let ascii = current?.asciiValue, (0x30...0x39).contains(ascii) {
            let (shifted, shiftOverflow) = (value ?? 0).multipliedReportingOverflow(by: 10)
            let (sum, sumOverflow) = shifted.addingReportingOverflow(Int(ascii - 0x30))
            guard !shiftOverflow, !sumOverflow else { return nil }
            value = sum
            index += 1
        }
        return value
    }

    mutating func characterClasses() -> Set<Character>? {
        var result = Set<Character>()
        repeat {
            skipWhitespace()
            if let current, current.isIdentifierCharacter {
                let name = identifier().lowercased()
                // Passwords are generated from ASCII only, so `unicode` narrows to ASCII printable
                let rawValue = name == "unicode" ? PasswordRules.CharacterClass.asciiPrintable.rawValue : name
                guard let characterClass = PasswordRules.CharacterClass(rawValue: rawValue) else {
                    return nil
                }
                result.formUnion(characterClass.characters)
            } else if current == "[" {
                guard let custom = customCharacterClass() else { return nil }
                result.formUnion(custom)
            } else {
                return nil
            }
            skipWhitespace()
        } while consume(",")
        return result
    }

    /// A `-` is only valid as the first character and is ignored elsewhere. A literal `]` must come last,
    /// written `]]`.
    private mutating func customCharacterClass() -> Set<Character>? {
        guard consume("[") else { return nil }
        let start = index
        var result = Set<Character>()
        while let character = current {
            index += 1
            guard character.isASCIIPrintable else { continue }
            if character == "-", index - 1 > start {
                continue
            }
            if character == "]" {
                if consume("]") {
                    result.insert("]")
                }
                return result
            }
            result.insert(character)
        }
        return nil
    }
}

private extension Character {
    var isRulesWhitespace: Bool {
        [" ", "\t", "\n", "\r", "\r\n", "\u{0C}"].contains(self)
    }

    var isIdentifierCharacter: Bool {
        isASCII && (isLetter || self == "-")
    }

    var isASCIIPrintable: Bool {
        asciiValue.map { (0x20...0x7E).contains($0) } ?? false
    }
}

private extension [Character] {
    var longestRunLength: Int {
        var longest = 0
        var current = 0
        var previous: Character?
        for character in self {
            current = character == previous ? current + 1 : 1
            longest = Swift.max(longest, current)
            previous = character
        }
        return longest
    }
}

private extension Set<Character> {
    static func ascii(_ ranges: ClosedRange<UInt8>...) -> Self {
        Set(ranges.joined().map { Character(Unicode.Scalar($0)) })
    }
}
