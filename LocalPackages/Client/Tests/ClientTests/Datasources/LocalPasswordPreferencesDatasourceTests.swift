//
// LocalPasswordPreferencesDatasourceTests.swift
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

@testable import Client
import Entities
import Foundation
import Testing

@Suite(.tags(.localDatasource))
struct LocalPasswordPreferencesDatasourceTests {
    let store: UserDefaults
    let sut: any LocalPasswordPreferencesDatasourceProtocol

    init() {
        let suiteName = "test.password.preferences.\(String.random())"
        store = UserDefaults(suiteName: suiteName)!
        store.removePersistentDomain(forName: suiteName)
        sut = LocalPasswordPreferencesDatasource(store: store)
    }

    @Test
    func `Return default preferences when nothing has been saved`() {
        let result = sut.getPreferences()

        let expected = PasswordPreferences.default
        #expect(result.characterCount == expected.characterCount)
        #expect(result.hasSpecialCharacters == expected.hasSpecialCharacters)
        #expect(result.hasCapitalCharacters == expected.hasCapitalCharacters)
        #expect(result.hasNumberCharacters == expected.hasNumberCharacters)
        #expect(result.wordSeparator == expected.wordSeparator)
        #expect(result.wordCount == expected.wordCount)
        #expect(result.capitalizingWords == expected.capitalizingWords)
        #expect(result.includingNumbers == expected.includingNumbers)
    }

    @Test
    func `Save and retrieve preserves every field`() {
        let given = PasswordPreferences(characterCount: 32,
                                        hasSpecialCharacters: false,
                                        hasCapitalCharacters: true,
                                        hasNumberCharacters: false,
                                        wordSeparator: .underscores,
                                        wordCount: 7,
                                        capitalizingWords: false,
                                        includingNumbers: true)

        sut.save(preferences: given)
        let result = sut.getPreferences()

        #expect(result.characterCount == given.characterCount)
        #expect(result.hasSpecialCharacters == given.hasSpecialCharacters)
        #expect(result.hasCapitalCharacters == given.hasCapitalCharacters)
        #expect(result.hasNumberCharacters == given.hasNumberCharacters)
        #expect(result.wordSeparator == given.wordSeparator)
        #expect(result.wordCount == given.wordCount)
        #expect(result.capitalizingWords == given.capitalizingWords)
        #expect(result.includingNumbers == given.includingNumbers)
    }

    @Test
    func `hasSpecialCharacters is persisted independently from hasNumberCharacters`() {
        let given = PasswordPreferences(characterCount: 16,
                                        hasSpecialCharacters: true,
                                        hasCapitalCharacters: false,
                                        hasNumberCharacters: false,
                                        wordSeparator: .commas,
                                        wordCount: 4,
                                        capitalizingWords: false,
                                        includingNumbers: false)

        sut.save(preferences: given)
        let result = sut.getPreferences()

        #expect(result.hasSpecialCharacters)
        #expect(!result.hasNumberCharacters)
    }

    @Test
    func `Saving again overwrites the previously stored preferences`() {
        let first = PasswordPreferences(characterCount: 12,
                                        hasSpecialCharacters: false,
                                        hasCapitalCharacters: false,
                                        hasNumberCharacters: false,
                                        wordSeparator: .hyphens,
                                        wordCount: 3,
                                        capitalizingWords: false,
                                        includingNumbers: false)
        sut.save(preferences: first)

        let second = PasswordPreferences(characterCount: 48,
                                         hasSpecialCharacters: true,
                                         hasCapitalCharacters: true,
                                         hasNumberCharacters: true,
                                         wordSeparator: .periods,
                                         wordCount: 8,
                                         capitalizingWords: true,
                                         includingNumbers: true)
        sut.save(preferences: second)

        let result = sut.getPreferences()
        #expect(result.characterCount == second.characterCount)
        #expect(result.hasSpecialCharacters == second.hasSpecialCharacters)
        #expect(result.hasCapitalCharacters == second.hasCapitalCharacters)
        #expect(result.hasNumberCharacters == second.hasNumberCharacters)
        #expect(result.wordSeparator == second.wordSeparator)
        #expect(result.wordCount == second.wordCount)
        #expect(result.capitalizingWords == second.capitalizingWords)
        #expect(result.includingNumbers == second.includingNumbers)
    }

    @Test
    func `All word separators survive a save/retrieve round trip`() {
        for separator in WordSeparator.allCases {
            let given = PasswordPreferences(characterCount: 20,
                                            hasSpecialCharacters: false,
                                            hasCapitalCharacters: false,
                                            hasNumberCharacters: false,
                                            wordSeparator: separator,
                                            wordCount: 5,
                                            capitalizingWords: false,
                                            includingNumbers: false)
            sut.save(preferences: given)
            #expect(sut.getPreferences().wordSeparator == separator)
        }
    }

    @Test
    func `An unknown stored separator value falls back to hyphens`() {
        // Persist an out-of-range raw value directly, bypassing the typed API.
        store.set(999, forKey: "PasswordWordSeparator")

        #expect(sut.getPreferences().wordSeparator == .hyphens)
    }
}

// MARK: - Legacy migration

extension LocalPasswordPreferencesDatasourceTests {
    private func seedLegacyPreferences(in store: UserDefaults) {
        store.set(28.0, forKey: LegacyPasswordPreferenceKey.characterCount.rawValue)
        store.set(false, forKey: LegacyPasswordPreferenceKey.hasSpecialCharacters.rawValue)
        store.set(true, forKey: LegacyPasswordPreferenceKey.hasCapitalCharacters.rawValue)
        store.set(false, forKey: LegacyPasswordPreferenceKey.hasNumberCharacters.rawValue)
        store.set(WordSeparator.underscores.rawValue, forKey: LegacyPasswordPreferenceKey.wordSeparator.rawValue)
        store.set(6.0, forKey: LegacyPasswordPreferenceKey.wordCount.rawValue)
        store.set(false, forKey: LegacyPasswordPreferenceKey.capitalizingWords.rawValue)
        store.set(true, forKey: LegacyPasswordPreferenceKey.includingNumbers.rawValue)
    }

    private func makeStore() -> (UserDefaults, String) {
        let suiteName = "test.password.preferences.\(String.random())"
        let store = UserDefaults(suiteName: suiteName)!
        store.removePersistentDomain(forName: suiteName)
        return (store, suiteName)
    }

    @Test
    func `Legacy preferences are migrated on init`() {
        let (store, _) = makeStore()
        seedLegacyPreferences(in: store)

        let sut = LocalPasswordPreferencesDatasource(store: store)
        let result = sut.getPreferences()

        #expect(result.characterCount == 28)
        #expect(!result.hasSpecialCharacters)
        #expect(result.hasCapitalCharacters)
        #expect(!result.hasNumberCharacters)
        #expect(result.wordSeparator == .underscores)
        #expect(result.wordCount == 6)
        #expect(!result.capitalizingWords)
        #expect(result.includingNumbers)
    }

    @Test
    func `Legacy keys are removed after migration`() {
        let (store, _) = makeStore()
        seedLegacyPreferences(in: store)

        _ = LocalPasswordPreferencesDatasource(store: store)

        for key in LegacyPasswordPreferenceKey.allCases {
            #expect(store.object(forKey: key.rawValue) == nil)
        }
    }

    @Test
    func `Migration runs only once and does not clobber later saved preferences`() {
        let (store, _) = makeStore()
        seedLegacyPreferences(in: store)

        // First instance migrates the legacy values and clears the legacy keys.
        let firstInstance = LocalPasswordPreferencesDatasource(store: store)

        // The user then tweaks their preferences.
        let updated = PasswordPreferences(characterCount: 50,
                                          hasSpecialCharacters: true,
                                          hasCapitalCharacters: true,
                                          hasNumberCharacters: true,
                                          wordSeparator: .spaces,
                                          wordCount: 9,
                                          capitalizingWords: true,
                                          includingNumbers: false)
        firstInstance.save(preferences: updated)

        // A second instance must not re-run the migration over the saved preferences.
        let secondInstance = LocalPasswordPreferencesDatasource(store: store)
        let result = secondInstance.getPreferences()

        #expect(result.characterCount == updated.characterCount)
        #expect(result.wordSeparator == updated.wordSeparator)
        #expect(result.wordCount == updated.wordCount)
        #expect(result.capitalizingWords == updated.capitalizingWords)
        #expect(result.includingNumbers == updated.includingNumbers)
    }

    @Test
    func `Default preferences are kept when there is nothing to migrate`() {
        let (store, _) = makeStore()

        let sut = LocalPasswordPreferencesDatasource(store: store)
        let result = sut.getPreferences()

        let expected = PasswordPreferences.default
        #expect(result.characterCount == expected.characterCount)
        #expect(result.wordSeparator == expected.wordSeparator)
        #expect(result.wordCount == expected.wordCount)
    }
}
