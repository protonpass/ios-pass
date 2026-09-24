//
// LocalUsernamePreferencesDatasource.swift
// Proton Pass - Created on 15/06/2026.
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

public protocol LocalUsernamePreferencesDatasourceProtocol: Sendable {
    func save(preferences: UsernamePreferences)
    func getPreferences() -> UsernamePreferences
}

private enum UsernamePreferenceKey: String {
    case wordCount = "UsernameWordCount"
    case separator = "UsernameSeparator"
    case includeNumbers = "UsernameIncludeNumbers"
    case capitalize = "UsernameCapitalize"
    case leetspeak = "UsernameLeetspeak"
    case includeAdjectives = "UsernameIncludeAdjectives"
    case includeNouns = "UsernameIncludeNouns"
    case includeVerbs = "UsernameIncludeVerbs"
}

public final class LocalUsernamePreferencesDatasource: LocalUsernamePreferencesDatasourceProtocol {
    private let store: UserDefaults

    public init(store: UserDefaults) {
        self.store = store
        let defaultPrefs = UsernamePreferences.default
        store.register(defaults: [
            UsernamePreferenceKey.wordCount.rawValue: defaultPrefs.wordCount,
            UsernamePreferenceKey.separator.rawValue: defaultPrefs.separator.rawValue,
            UsernamePreferenceKey.includeNumbers.rawValue: defaultPrefs.includeNumbers,
            UsernamePreferenceKey.capitalize.rawValue: defaultPrefs.capitalize,
            UsernamePreferenceKey.leetspeak.rawValue: defaultPrefs.leetspeak,
            UsernamePreferenceKey.includeAdjectives.rawValue: defaultPrefs.includeAdjectives,
            UsernamePreferenceKey.includeNouns.rawValue: defaultPrefs.includeNouns,
            UsernamePreferenceKey.includeVerbs.rawValue: defaultPrefs.includeVerbs
        ])
    }

    public func save(preferences: UsernamePreferences) {
        store.set(preferences.wordCount, forKey: UsernamePreferenceKey.wordCount.rawValue)
        store.set(preferences.separator.rawValue, forKey: UsernamePreferenceKey.separator.rawValue)
        store.set(preferences.includeNumbers, forKey: UsernamePreferenceKey.includeNumbers.rawValue)
        store.set(preferences.capitalize, forKey: UsernamePreferenceKey.capitalize.rawValue)
        store.set(preferences.leetspeak, forKey: UsernamePreferenceKey.leetspeak.rawValue)
        store.set(preferences.includeAdjectives, forKey: UsernamePreferenceKey.includeAdjectives.rawValue)
        store.set(preferences.includeNouns, forKey: UsernamePreferenceKey.includeNouns.rawValue)
        store.set(preferences.includeVerbs, forKey: UsernamePreferenceKey.includeVerbs.rawValue)
    }

    public func getPreferences() -> UsernamePreferences {
        let wordCount = store.integer(forKey: UsernamePreferenceKey.wordCount.rawValue)
        let separatorValue = store.integer(forKey: UsernamePreferenceKey.separator.rawValue)
        let separator = WordSeparator(rawValue: separatorValue) ?? .hyphens
        let includeNumbers = store.bool(forKey: UsernamePreferenceKey.includeNumbers.rawValue)
        let capitalize = store.bool(forKey: UsernamePreferenceKey.capitalize.rawValue)
        let leetspeak = store.bool(forKey: UsernamePreferenceKey.leetspeak.rawValue)
        let includeAdjectives = store.bool(forKey: UsernamePreferenceKey.includeAdjectives.rawValue)
        let includeNouns = store.bool(forKey: UsernamePreferenceKey.includeNouns.rawValue)
        let includeVerbs = store.bool(forKey: UsernamePreferenceKey.includeVerbs.rawValue)
        return .init(wordCount: wordCount,
                     separator: separator,
                     includeNumbers: includeNumbers,
                     capitalize: capitalize,
                     leetspeak: leetspeak,
                     includeAdjectives: includeAdjectives,
                     includeNouns: includeNouns,
                     includeVerbs: includeVerbs)
    }
}
