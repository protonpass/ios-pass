//
// PasswordPolicyResolverTests.swift
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

@testable import Entities
import Testing

struct PasswordPolicyResolverTests {
    // MARK: - clamp

    @Test
    func `clamp keeps a value that is already within range`() {
        #expect(PasswordPolicyResolver.clamp(10, to: 4...64) == 10)
    }

    @Test
    func `clamp raises a value below the lower bound`() {
        #expect(PasswordPolicyResolver.clamp(2, to: 4...64) == 4)
    }

    @Test
    func `clamp lowers a value above the upper bound`() {
        #expect(PasswordPolicyResolver.clamp(80, to: 4...64) == 64)
    }

    // MARK: - Type restriction

    @Test
    func `disallowing random passwords forces the memorable type`() {
        let preferences = makePreferences(passwordType: .random)
        let policy = makePolicy(randomAllowed: false)

        let resolution = PasswordPolicyResolver.resolve(preferences: preferences, policy: policy)

        #expect(resolution.preferences.passwordType == .memorable)
        #expect(!resolution.allowsTypeSelection)
    }

    @Test
    func `disallowing memorable passwords forces the random type`() {
        let preferences = makePreferences(passwordType: .memorable)
        let policy = makePolicy(memorableAllowed: false)

        let resolution = PasswordPolicyResolver.resolve(preferences: preferences, policy: policy)

        #expect(resolution.preferences.passwordType == .random)
        #expect(!resolution.allowsTypeSelection)
    }

    @Test
    func `allowing both types preserves the chosen type and enables selection`() {
        let preferences = makePreferences(passwordType: .memorable)
        let policy = makePolicy(randomAllowed: true, memorableAllowed: true)

        let resolution = PasswordPolicyResolver.resolve(preferences: preferences, policy: policy)

        #expect(resolution.preferences.passwordType == .memorable)
        #expect(resolution.allowsTypeSelection)
    }

    // MARK: - Count clamping & bounds

    @Test
    func `character and word counts are clamped into the policy bounds`() {
        let tooLow = makePreferences(characterCount: 2, wordCount: 0)
        let lowResolution = PasswordPolicyResolver.resolve(preferences: tooLow,
                                                           policy: makePolicy(randomMinLength: 8,
                                                                              memorableMinWords: 3))
        #expect(lowResolution.preferences.characterCount == 8)
        #expect(lowResolution.preferences.wordCount == 3)

        let tooHigh = makePreferences(characterCount: 200, wordCount: 50)
        let highResolution = PasswordPolicyResolver.resolve(preferences: tooHigh,
                                                            policy: makePolicy(randomMaxLength: 32,
                                                                               memorableMaxWords: 6))
        #expect(highResolution.preferences.characterCount == 32)
        #expect(highResolution.preferences.wordCount == 6)
    }

    @Test
    func `bounds mirror the policy limits`() {
        let policy = makePolicy(randomMinLength: 6,
                                randomMaxLength: 40,
                                memorableMinWords: 2,
                                memorableMaxWords: 8)

        let bounds = PasswordPolicyResolver.resolve(preferences: makePreferences(), policy: policy).bounds

        #expect(bounds == .init(minCharacterCount: 6,
                                maxCharacterCount: 40,
                                minWordCount: 2,
                                maxWordCount: 8))
    }

    // MARK: - Mandatory options

    @Test
    func `mandatory options override the user's choices`() {
        let preferences = makePreferences(hasSpecialCharacters: false,
                                          hasCapitalCharacters: false,
                                          hasNumberCharacters: false,
                                          capitalizingWords: false,
                                          includingNumbers: false)
        let policy = makePolicy(mustIncludeNumbers: true,
                                mustIncludeSymbols: true,
                                mustIncludeUppercase: true,
                                mustCapitalize: true,
                                memorableMustIncludeNumbers: true)

        let resolved = PasswordPolicyResolver.resolve(preferences: preferences, policy: policy).preferences

        #expect(resolved.hasSpecialCharacters)
        #expect(resolved.hasCapitalCharacters)
        #expect(resolved.hasNumberCharacters)
        #expect(resolved.capitalizingWords)
        #expect(resolved.includingNumbers)
    }

    @Test
    func `unset mandatory options keep the user's choices`() {
        let preferences = makePreferences(hasSpecialCharacters: false,
                                          hasCapitalCharacters: true,
                                          hasNumberCharacters: false,
                                          capitalizingWords: false,
                                          includingNumbers: true)
        // A policy with all mandatory flags nil (the `makePolicy` defaults).
        let resolved = PasswordPolicyResolver.resolve(preferences: preferences,
                                                      policy: makePolicy()).preferences

        #expect(!resolved.hasSpecialCharacters)
        #expect(resolved.hasCapitalCharacters)
        #expect(!resolved.hasNumberCharacters)
        #expect(!resolved.capitalizingWords)
        #expect(resolved.includingNumbers)
    }

    // MARK: - Separator coercion

    @Test
    func `a number-based separator is replaced when numbers are excluded`() {
        for separator in [WordSeparator.numbers, .numbersAndSymbols] {
            let preferences = makePreferences(wordSeparator: separator, includingNumbers: true)
            let policy = makePolicy(memorableMustIncludeNumbers: false)

            let resolved = PasswordPolicyResolver.resolve(preferences: preferences, policy: policy).preferences

            #expect(!resolved.includingNumbers)
            #expect(resolved.wordSeparator == .commas)
        }
    }

    @Test
    func `a number-based separator is preserved when numbers remain included`() {
        let preferences = makePreferences(wordSeparator: .numbers, includingNumbers: true)
        let policy = makePolicy(memorableMustIncludeNumbers: true)

        let resolved = PasswordPolicyResolver.resolve(preferences: preferences, policy: policy).preferences

        #expect(resolved.includingNumbers)
        #expect(resolved.wordSeparator == .numbers)
    }

    // MARK: - Locked options

    @Test
    func `locked options mirror which policy flags are set, regardless of their value`() {
        let policy = makePolicy(mustIncludeNumbers: true,
                                mustIncludeSymbols: false,
                                mustIncludeUppercase: nil,
                                mustCapitalize: true,
                                memorableMustIncludeNumbers: nil)

        let locked = PasswordPolicyResolver.resolve(preferences: makePreferences(), policy: policy).lockedOptions

        // A set flag locks the toggle even when the mandated value is `false`.
        #expect(locked.numberCharacters)
        #expect(locked.specialCharacters)
        #expect(locked.capitalizingWords)
        // A `nil` flag leaves the option user-editable.
        #expect(!locked.capitalCharacters)
        #expect(!locked.includingNumbers)
    }

    @Test
    func `no options are locked when the policy sets no mandatory flags`() {
        let locked = PasswordPolicyResolver.resolve(preferences: makePreferences(),
                                                    policy: makePolicy()).lockedOptions
        #expect(locked == .unlocked)
    }
}

// MARK: - Builders

private func makePreferences(passwordType: PasswordType = .random,
                             characterCount: Int = 20,
                             hasSpecialCharacters: Bool = true,
                             hasCapitalCharacters: Bool = true,
                             hasNumberCharacters: Bool = true,
                             wordSeparator: WordSeparator = .hyphens,
                             wordCount: Int = 5,
                             capitalizingWords: Bool = true,
                             includingNumbers: Bool = true) -> PasswordPreferences {
    PasswordPreferences(passwordType: passwordType,
                        characterCount: characterCount,
                        hasSpecialCharacters: hasSpecialCharacters,
                        hasCapitalCharacters: hasCapitalCharacters,
                        hasNumberCharacters: hasNumberCharacters,
                        wordSeparator: wordSeparator,
                        wordCount: wordCount,
                        capitalizingWords: capitalizingWords,
                        includingNumbers: includingNumbers)
}

// swiftlint:disable discouraged_optional_boolean
private func makePolicy(randomAllowed: Bool = true,
                        randomMinLength: Int? = 4,
                        randomMaxLength: Int? = 64,
                        mustIncludeNumbers: Bool? = nil,
                        mustIncludeSymbols: Bool? = nil,
                        mustIncludeUppercase: Bool? = nil,
                        memorableAllowed: Bool = true,
                        memorableMinWords: Int? = 1,
                        memorableMaxWords: Int? = 10,
                        mustCapitalize: Bool? = nil,
                        memorableMustIncludeNumbers: Bool? = nil) -> PasswordPolicy {
    PasswordPolicy(randomPasswordAllowed: randomAllowed,
                   randomPasswordMinLength: randomMinLength,
                   randomPasswordMaxLength: randomMaxLength,
                   randomPasswordMustIncludeNumbers: mustIncludeNumbers,
                   randomPasswordMustIncludeSymbols: mustIncludeSymbols,
                   randomPasswordMustIncludeUppercase: mustIncludeUppercase,
                   memorablePasswordAllowed: memorableAllowed,
                   memorablePasswordMinWords: memorableMinWords,
                   memorablePasswordMaxWords: memorableMaxWords,
                   memorablePasswordMustCapitalize: mustCapitalize,
                   memorablePasswordMustIncludeNumbers: memorableMustIncludeNumbers)
}

// swiftlint:enable discouraged_optional_boolean
