//
// PasswordPolicyResolver.swift
// Proton Pass - Created on 02/07/2026.
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

/// Pure resolution of the effective password-generator settings under an organisation
/// `PasswordPolicy`. Deliberately free of any UI or view-model state so the clamping and
/// type-restriction rules can be unit-tested in isolation.
public enum PasswordPolicyResolver {
    public struct Bounds: Sendable, Equatable {
        public let minCharacterCount: Double
        public let maxCharacterCount: Double
        public let minWordCount: Double
        public let maxWordCount: Double

        public init(minCharacterCount: Double,
                    maxCharacterCount: Double,
                    minWordCount: Double,
                    maxWordCount: Double) {
            self.minCharacterCount = minCharacterCount
            self.maxCharacterCount = maxCharacterCount
            self.minWordCount = minWordCount
            self.maxWordCount = maxWordCount
        }
    }

    /// Which option toggles the policy dictates. A locked option must be presented as read-only:
    /// the policy pins its value (regardless of whether that value is on or off), so the user may
    /// not change it.
    public struct LockedOptions: Sendable, Equatable {
        public let specialCharacters: Bool
        public let capitalCharacters: Bool
        public let numberCharacters: Bool
        public let capitalizingWords: Bool
        public let includingNumbers: Bool

        /// No policy in effect: every option is user-editable.
        public static let unlocked = LockedOptions(specialCharacters: false,
                                                   capitalCharacters: false,
                                                   numberCharacters: false,
                                                   capitalizingWords: false,
                                                   includingNumbers: false)

        public init(specialCharacters: Bool,
                    capitalCharacters: Bool,
                    numberCharacters: Bool,
                    capitalizingWords: Bool,
                    includingNumbers: Bool) {
            self.specialCharacters = specialCharacters
            self.capitalCharacters = capitalCharacters
            self.numberCharacters = numberCharacters
            self.capitalizingWords = capitalizingWords
            self.includingNumbers = includingNumbers
        }
    }

    public struct Resolution: Sendable, Equatable {
        public let preferences: PasswordPreferences
        public let bounds: Bounds
        public let allowsTypeSelection: Bool
        public let lockedOptions: LockedOptions

        public init(preferences: PasswordPreferences,
                    bounds: Bounds,
                    allowsTypeSelection: Bool,
                    lockedOptions: LockedOptions) {
            self.preferences = preferences
            self.bounds = bounds
            self.allowsTypeSelection = allowsTypeSelection
            self.lockedOptions = lockedOptions
        }
    }

    /// Clamp `value` into `range`, returning the nearest bound when out of range.
    public static func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        if range.contains(value) {
            value
        } else if value < range.lowerBound {
            range.lowerBound
        } else {
            range.upperBound
        }
    }

    /// Resolve `preferences` against `policy`: applies the policy's mandatory options, clamps the
    /// character/word counts to the allowed range, coerces an incompatible word separator, and
    /// reports whether the user may still switch password type.
    public static func resolve(preferences: PasswordPreferences,
                               policy: PasswordPolicy) -> Resolution {
        var passwordType = preferences.passwordType
        if !policy.randomPasswordAllowed {
            passwordType = .memorable
        }
        if !policy.memorablePasswordAllowed, passwordType == .memorable {
            passwordType = .random
        }

        let bounds = Bounds(minCharacterCount: Double(policy.randomPasswordMinLength),
                            maxCharacterCount: Double(policy.randomPasswordMaxLength),
                            minWordCount: Double(policy.memorablePasswordMinWords),
                            maxWordCount: Double(policy.memorablePasswordMaxWords))

        let includingNumbers = policy.memorablePasswordMustIncludeNumbers ?? preferences.includingNumbers

        var wordSeparator = preferences.wordSeparator
        if !includingNumbers, wordSeparator == .numbersAndSymbols || wordSeparator == .numbers {
            wordSeparator = .commas
        }

        let resolved =
            PasswordPreferences(passwordType: passwordType,
                                characterCount: Int(clamp(Double(preferences.characterCount),
                                                          to: bounds.minCharacterCount...bounds
                                                              .maxCharacterCount)),
                                hasSpecialCharacters: policy.randomPasswordMustIncludeSymbols ?? preferences
                                    .hasSpecialCharacters,
                                hasCapitalCharacters: policy.randomPasswordMustIncludeUppercase ?? preferences
                                    .hasCapitalCharacters,
                                hasNumberCharacters: policy.randomPasswordMustIncludeNumbers ?? preferences
                                    .hasNumberCharacters,
                                wordSeparator: wordSeparator,
                                wordCount: Int(clamp(Double(preferences.wordCount),
                                                     to: bounds.minWordCount...bounds.maxWordCount)),
                                capitalizingWords: policy.memorablePasswordMustCapitalize ?? preferences
                                    .capitalizingWords,
                                includingNumbers: includingNumbers)

        let lockedOptions = LockedOptions(specialCharacters: policy.randomPasswordMustIncludeSymbols != nil,
                                          capitalCharacters: policy.randomPasswordMustIncludeUppercase != nil,
                                          numberCharacters: policy.randomPasswordMustIncludeNumbers != nil,
                                          capitalizingWords: policy.memorablePasswordMustCapitalize != nil,
                                          includingNumbers: policy.memorablePasswordMustIncludeNumbers != nil)

        return Resolution(preferences: resolved,
                          bounds: bounds,
                          allowsTypeSelection: policy.randomPasswordAllowed && policy.memorablePasswordAllowed,
                          lockedOptions: lockedOptions)
    }
}
