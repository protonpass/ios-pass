//
// LocalUsernamePreferencesDatasourceTests.swift
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

@testable import Client
import Entities
import Foundation
import Testing

@Suite(.tags(.localDatasource))
struct LocalUsernamePreferencesDatasourceTests {
    let store: UserDefaults
    let sut: any LocalUsernamePreferencesDatasourceProtocol

    init() {
        let suiteName = "test.username.preferences.\(String.random())"
        store = UserDefaults(suiteName: suiteName)!
        store.removePersistentDomain(forName: suiteName)
        sut = LocalUsernamePreferencesDatasource(store: store)
    }

    @Test("Return default preferences when nothing has been saved")
    func returnsDefaultsWhenEmpty() {
        let result = sut.getPreferences()

        let expected = UsernamePreferences.default
        #expect(result.wordCount == expected.wordCount)
        #expect(result.separator == expected.separator)
        #expect(result.includeNumbers == expected.includeNumbers)
        #expect(result.capitalize == expected.capitalize)
        #expect(result.leetspeak == expected.leetspeak)
        #expect(result.includeAdjectives == expected.includeAdjectives)
        #expect(result.includeNouns == expected.includeNouns)
        #expect(result.includeVerbs == expected.includeVerbs)
    }

    @Test("Save and retrieve preserves every field")
    func saveAndRetrieveRoundTrip() {
        let given = UsernamePreferences(wordCount: 4,
                                        separator: .underscores,
                                        includeNumbers: true,
                                        capitalize: true,
                                        leetspeak: false,
                                        includeAdjectives: false,
                                        includeNouns: false,
                                        includeVerbs: true)

        sut.save(preferences: given)
        let result = sut.getPreferences()

        #expect(result.wordCount == given.wordCount)
        #expect(result.separator == given.separator)
        #expect(result.includeNumbers == given.includeNumbers)
        #expect(result.capitalize == given.capitalize)
        #expect(result.leetspeak == given.leetspeak)
        #expect(result.includeAdjectives == given.includeAdjectives)
        #expect(result.includeNouns == given.includeNouns)
        #expect(result.includeVerbs == given.includeVerbs)
    }

    @Test("includeNumbers is persisted independently from includeNouns")
    func includeNumbersIsIndependentFromIncludeNouns() {
        let given = UsernamePreferences(wordCount: 3,
                                        separator: .commas,
                                        includeNumbers: true,
                                        capitalize: false,
                                        leetspeak: false,
                                        includeAdjectives: false,
                                        includeNouns: false,
                                        includeVerbs: false)

        sut.save(preferences: given)
        let result = sut.getPreferences()

        #expect(result.includeNumbers)
        #expect(!result.includeNouns)
    }

    @Test("Saving again overwrites the previously stored preferences")
    func saveOverwritesPreviousValues() {
        let first = UsernamePreferences(wordCount: 2,
                                        separator: .hyphens,
                                        includeNumbers: false,
                                        capitalize: false,
                                        leetspeak: false,
                                        includeAdjectives: true,
                                        includeNouns: true,
                                        includeVerbs: false)
        sut.save(preferences: first)

        let second = UsernamePreferences(wordCount: 5,
                                         separator: .periods,
                                         includeNumbers: true,
                                         capitalize: true,
                                         leetspeak: true,
                                         includeAdjectives: false,
                                         includeNouns: false,
                                         includeVerbs: true)
        sut.save(preferences: second)

        let result = sut.getPreferences()
        #expect(result.wordCount == second.wordCount)
        #expect(result.separator == second.separator)
        #expect(result.includeNumbers == second.includeNumbers)
        #expect(result.capitalize == second.capitalize)
        #expect(result.leetspeak == second.leetspeak)
        #expect(result.includeAdjectives == second.includeAdjectives)
        #expect(result.includeNouns == second.includeNouns)
        #expect(result.includeVerbs == second.includeVerbs)
    }

    @Test("All word separators survive a save/retrieve round trip")
    func everySeparatorRoundTrips() {
        for separator in WordSeparator.allCases {
            let given = UsernamePreferences(wordCount: 2,
                                            separator: separator,
                                            includeNumbers: false,
                                            capitalize: false,
                                            leetspeak: false,
                                            includeAdjectives: false,
                                            includeNouns: false,
                                            includeVerbs: false)
            sut.save(preferences: given)
            #expect(sut.getPreferences().separator == separator)
        }
    }

    @Test("An unknown stored separator value falls back to hyphens")
    func unknownSeparatorFallsBackToHyphens() {
        // Persist an out-of-range raw value directly, bypassing the typed API.
        store.set(999, forKey: "UsernameSeparator")

        #expect(sut.getPreferences().separator == .hyphens)
    }
}
