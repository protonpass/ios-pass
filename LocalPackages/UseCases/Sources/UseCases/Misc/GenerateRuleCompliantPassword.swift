//
// GenerateRuleCompliantPassword.swift
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

import Core
import Entities

// sourcery: AutoMockable
public protocol GenerateRuleCompliantPasswordUseCase: Sendable {
    /// Returns `nil` when no password can satisfy `rules`. Never contains a space.
    func callAsFunction(rules: PasswordRules, preferredLength: Int) -> String?
}

public struct GenerateRuleCompliantPassword: GenerateRuleCompliantPasswordUseCase {
    public init() {}

    public func callAsFunction(rules: PasswordRules, preferredLength: Int) -> String? {
        // Forms often trim spaces, and Apple's `special` class includes one
        let pool = rules.allowed.subtracting([" "])
        let requiredSets = rules.requiredSets.map { $0.intersection(pool) }
        guard !pool.isEmpty, !requiredSets.contains(where: \.isEmpty) else { return nil }

        let minLength = max(rules.minLength ?? 1, requiredSets.count)
        let maxLength = rules.maxLength ?? max(preferredLength, minLength)
        guard minLength <= maxLength else { return nil }
        let length = preferredLength.clamp(to: minLength...maxLength)

        let strengtheningSets = [PasswordRules.CharacterClass.lower, .upper, .digit]
            .map { $0.characters.intersection(pool) }
            .filter { !$0.isEmpty }
        let guaranteedPools = (requiredSets + strengtheningSets.prefix(length - requiredSets.count))
            .map { Array($0) }
        let poolCharacters = Array(pool)
        var generator = SystemRandomNumberGenerator()

        // Retrying is enough for `maxConsecutive`: Apple's quirks list never goes below 2, where a retry is
        // rarely needed. A one-character pool with a limit below the length exhausts the attempts.
        for _ in 0..<100 {
            var characters = guaranteedPools.compactMap { $0.randomElement(using: &generator) }
            characters += (characters.count..<length).compactMap { _ in
                poolCharacters.randomElement(using: &generator)
            }
            characters.shuffle(using: &generator)
            let password = String(characters)
            if rules.isSatisfied(by: password) {
                return password
            }
        }
        return nil
    }
}
