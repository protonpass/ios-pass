//
//
// PasswordPolicyResolver.swift
// Proton Pass - Created on 06/07/2026.
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
//

import Core
import Entities

public protocol ResolvePasswordPolicyUseCase: Sendable {
    func callAsFunction(preferences: PasswordPreferences,
                        policy: PasswordPolicy) -> PasswordPolicyResolution
}

public struct ResolvePasswordPolicy: ResolvePasswordPolicyUseCase {
    public init() {}

    public func callAsFunction(preferences: PasswordPreferences,
                               policy: PasswordPolicy) -> PasswordPolicyResolution {
        let bounds = PasswordPolicyBounds(minCharacterCount: policy.randomPasswordMinLength,
                                          maxCharacterCount: policy.randomPasswordMaxLength,
                                          minWordCount: policy.memorablePasswordMinWords,
                                          maxWordCount: policy.memorablePasswordMaxWords)

        let resolvedPreference = resolve(current: preferences, with: policy, and: bounds)

        return PasswordPolicyResolution(preferences: resolvedPreference,
                                        bounds: bounds,
                                        allowsTypeSelection: policy.randomPasswordAllowed && policy
                                            .memorablePasswordAllowed,
                                        lockedOptions: policy.lockedOptions)
    }
}

extension ResolvePasswordPolicy {
    func resolve(current preferences: PasswordPreferences,
                 with policy: PasswordPolicy,
                 and bounds: PasswordPolicyBounds) -> PasswordPreferences {
        var passwordType = preferences.passwordType
        if !policy.randomPasswordAllowed {
            passwordType = .memorable
        }
        if !policy.memorablePasswordAllowed, passwordType == .memorable {
            passwordType = .random
        }

        let includingNumbers = policy.memorablePasswordMustIncludeNumbers ?? preferences.includingNumbers

        var wordSeparator = preferences.wordSeparator
        if !includingNumbers, wordSeparator == .numbersAndSymbols || wordSeparator == .numbers {
            wordSeparator = .commas
        }

        return PasswordPreferences(passwordType: passwordType,
                                   characterCount: preferences.characterCount
                                       .clamp(to: bounds.minCharacterCount...bounds
                                           .maxCharacterCount),
                                   hasSpecialCharacters: policy.randomPasswordMustIncludeSymbols ?? preferences
                                       .hasSpecialCharacters,
                                   hasCapitalCharacters: policy
                                       .randomPasswordMustIncludeUppercase ?? preferences
                                       .hasCapitalCharacters,
                                   hasNumberCharacters: policy.randomPasswordMustIncludeNumbers ?? preferences
                                       .hasNumberCharacters,
                                   wordSeparator: wordSeparator,
                                   wordCount: preferences.wordCount
                                       .clamp(to: bounds.minWordCount...bounds.maxWordCount),
                                   capitalizingWords: policy.memorablePasswordMustCapitalize ?? preferences
                                       .capitalizingWords,
                                   includingNumbers: includingNumbers)
    }
}
