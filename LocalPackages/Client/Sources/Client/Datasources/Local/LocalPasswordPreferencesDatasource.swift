//
// LocalPasswordPreferencesDatasource.swift
// Proton Pass - Created on 25/06/2026.
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

import Entities
import Foundation

public protocol LocalPasswordPreferencesDatasourceProtocol: Sendable {
    func save(preferences: PasswordPreferences)
    func getPreferences() -> PasswordPreferences
}

private enum PasswordPreferenceKey: String {
    case passwordType = "PasswordType"
    case characterCount = "PasswordCharacterCount"
    case hasSpecialCharacters = "PasswordHasSpecialCharacters"
    case hasCapitalCharacters = "PasswordHasCapitalCharacters"
    case hasNumberCharacters = "PasswordHasNumberCharacters"
    case wordSeparator = "PasswordWordSeparator"
    case wordCount = "PasswordWordCount"
    case capitalizingWords = "PasswordCapitalizingWords"
    case includingNumbers = "PasswordIncludingNumbers"
}

/// Keys used by the legacy `GeneratePasswordViewModel` `@AppStorage` properties.
public enum LegacyPasswordPreferenceKey: String, CaseIterable, Sendable {
    case passwordType
    case characterCount
    case hasSpecialCharacters
    case hasCapitalCharacters
    case hasNumberCharacters
    case wordSeparator
    case wordCount
    case capitalizingWords
    case includingNumbers
}

public final class LocalPasswordPreferencesDatasource: LocalPasswordPreferencesDatasourceProtocol {
    private let store: UserDefaults

    public init(store: UserDefaults) {
        self.store = store
        let defaultPrefs = PasswordPreferences.default
        store.register(defaults: [
            PasswordPreferenceKey.passwordType.rawValue: defaultPrefs.passwordType.rawValue,
            PasswordPreferenceKey.characterCount.rawValue: defaultPrefs.characterCount,
            PasswordPreferenceKey.hasSpecialCharacters.rawValue: defaultPrefs.hasSpecialCharacters,
            PasswordPreferenceKey.hasCapitalCharacters.rawValue: defaultPrefs.hasCapitalCharacters,
            PasswordPreferenceKey.hasNumberCharacters.rawValue: defaultPrefs.hasNumberCharacters,
            PasswordPreferenceKey.wordSeparator.rawValue: defaultPrefs.wordSeparator.rawValue,
            PasswordPreferenceKey.wordCount.rawValue: defaultPrefs.wordCount,
            PasswordPreferenceKey.capitalizingWords.rawValue: defaultPrefs.capitalizingWords,
            PasswordPreferenceKey.includingNumbers.rawValue: defaultPrefs.includingNumbers
        ])
        migrateLegacyPreferences()
    }

    public func save(preferences: PasswordPreferences) {
        store.set(preferences.passwordType.rawValue, forKey: PasswordPreferenceKey.passwordType.rawValue)
        store.set(preferences.characterCount, forKey: PasswordPreferenceKey.characterCount.rawValue)
        store.set(preferences.hasSpecialCharacters, forKey: PasswordPreferenceKey.hasSpecialCharacters.rawValue)
        store.set(preferences.hasCapitalCharacters, forKey: PasswordPreferenceKey.hasCapitalCharacters.rawValue)
        store.set(preferences.hasNumberCharacters, forKey: PasswordPreferenceKey.hasNumberCharacters.rawValue)
        store.set(preferences.wordSeparator.rawValue, forKey: PasswordPreferenceKey.wordSeparator.rawValue)
        store.set(preferences.wordCount, forKey: PasswordPreferenceKey.wordCount.rawValue)
        store.set(preferences.capitalizingWords, forKey: PasswordPreferenceKey.capitalizingWords.rawValue)
        store.set(preferences.includingNumbers, forKey: PasswordPreferenceKey.includingNumbers.rawValue)
    }

    public func getPreferences() -> PasswordPreferences {
        let passwordTypeValue = store.integer(forKey: PasswordPreferenceKey.passwordType.rawValue)
        let passwordType = PasswordType(rawValue: passwordTypeValue) ?? .memorable
        let characterCount = store.integer(forKey: PasswordPreferenceKey.characterCount.rawValue)
        let hasSpecialCharacters = store.bool(forKey: PasswordPreferenceKey.hasSpecialCharacters.rawValue)
        let hasCapitalCharacters = store.bool(forKey: PasswordPreferenceKey.hasCapitalCharacters.rawValue)
        let hasNumberCharacters = store.bool(forKey: PasswordPreferenceKey.hasNumberCharacters.rawValue)
        let separatorValue = store.integer(forKey: PasswordPreferenceKey.wordSeparator.rawValue)
        let wordSeparator = WordSeparator(rawValue: separatorValue) ?? .hyphens
        let wordCount = store.integer(forKey: PasswordPreferenceKey.wordCount.rawValue)
        let capitalizingWords = store.bool(forKey: PasswordPreferenceKey.capitalizingWords.rawValue)
        let includingNumbers = store.bool(forKey: PasswordPreferenceKey.includingNumbers.rawValue)
        return .init(passwordType: passwordType,
                     characterCount: characterCount,
                     hasSpecialCharacters: hasSpecialCharacters,
                     hasCapitalCharacters: hasCapitalCharacters,
                     hasNumberCharacters: hasNumberCharacters,
                     wordSeparator: wordSeparator,
                     wordCount: wordCount,
                     capitalizingWords: capitalizingWords,
                     includingNumbers: includingNumbers)
    }
}

// MARK: - Migration

// swiftlint:disable:next todo
// TODO: Migration path introduced in July 2026, can be removed several months later
private extension LocalPasswordPreferencesDatasource {
    func migrateLegacyPreferences() {
        guard LegacyPasswordPreferenceKey.allCases
            .contains(where: { store.object(forKey: $0.rawValue) != nil }) else {
            return
        }

        let defaultPrefs = PasswordPreferences.default
        let preferences =
            PasswordPreferences(passwordType: legacyPasswordType(fallback: defaultPrefs.passwordType),
                                characterCount: legacyInt(.characterCount,
                                                          fallback: defaultPrefs.characterCount),
                                hasSpecialCharacters: legacyBool(.hasSpecialCharacters,
                                                                 fallback: defaultPrefs.hasSpecialCharacters),
                                hasCapitalCharacters: legacyBool(.hasCapitalCharacters,
                                                                 fallback: defaultPrefs.hasCapitalCharacters),
                                hasNumberCharacters: legacyBool(.hasNumberCharacters,
                                                                fallback: defaultPrefs.hasNumberCharacters),
                                wordSeparator: legacyWordSeparator(fallback: defaultPrefs.wordSeparator),
                                wordCount: legacyInt(.wordCount, fallback: defaultPrefs.wordCount),
                                capitalizingWords: legacyBool(.capitalizingWords,
                                                              fallback: defaultPrefs.capitalizingWords),
                                includingNumbers: legacyBool(.includingNumbers,
                                                             fallback: defaultPrefs.includingNumbers))
        save(preferences: preferences)

        for key in LegacyPasswordPreferenceKey.allCases {
            store.removeObject(forKey: key.rawValue)
        }
    }

    func legacyPasswordType(fallback: PasswordType) -> PasswordType {
        guard store.object(forKey: LegacyPasswordPreferenceKey.passwordType.rawValue) != nil else {
            return fallback
        }
        let rawValue = store.integer(forKey: LegacyPasswordPreferenceKey.passwordType.rawValue)
        return PasswordType(rawValue: rawValue) ?? fallback
    }

    func legacyInt(_ key: LegacyPasswordPreferenceKey, fallback: Int) -> Int {
        guard store.object(forKey: key.rawValue) != nil else { return fallback }
        return store.integer(forKey: key.rawValue)
    }

    func legacyBool(_ key: LegacyPasswordPreferenceKey, fallback: Bool) -> Bool {
        guard store.object(forKey: key.rawValue) != nil else { return fallback }
        return store.bool(forKey: key.rawValue)
    }

    func legacyWordSeparator(fallback: WordSeparator) -> WordSeparator {
        guard store.object(forKey: LegacyPasswordPreferenceKey.wordSeparator.rawValue) != nil else {
            return fallback
        }
        let rawValue = store.integer(forKey: LegacyPasswordPreferenceKey.wordSeparator.rawValue)
        return WordSeparator(rawValue: rawValue) ?? fallback
    }
}
