//
// UsernameGeneratorViewModel.swift
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

import Client
import DIComposition
import Entities
import FactoryKit
import Foundation
import UseCases

@MainActor
@Observable
final class UsernameGeneratorViewModel {
    private(set) var username = ""
    var wordCount: Double = 2
    var separator: WordSeparator = .hyphens
    var includeNumbers = true
    var capitalize = false
    var leetspeak = false
    var includeAdjectives = true
    var includeNouns = true
    var includeVerbs = false

    private let generateUsername = dependency(\UseCasesContainer.generateUsername)
    private let datasource = dependency(\RepositoryContainer.localUsernamePreferencesDatasource)

    @ObservationIgnored
    private let onResult: (Result<String, any Error>) -> Void

    var preferences: UsernamePreferences {
        .init(wordCount: Int(wordCount),
              separator: separator,
              includeNumbers: includeNumbers,
              capitalize: capitalize,
              leetspeak: leetspeak,
              includeAdjectives: includeAdjectives,
              includeNouns: includeNouns,
              includeVerbs: includeVerbs)
    }

    init(onResult: @escaping (Result<String, any Error>) -> Void) {
        self.onResult = onResult

        retrievePreferences()
    }

    func regenerate() {
        do {
            username = try generateUsername(wordCount: Int(wordCount),
                                            includeNumbers: includeNumbers,
                                            capitalise: capitalize,
                                            separator: separator,
                                            leetSpeak: leetspeak,
                                            wordTypes: .init(adjectives: includeAdjectives,
                                                             nouns: includeNouns,
                                                             verbs: includeVerbs))
        } catch {
            onResult(.failure(error))
        }
    }

    func confirm() {
        onResult(.success(username))
    }

    func persistAndRegenerate() {
        datasource.save(preferences: preferences)
        regenerate()
    }
}

private extension UsernameGeneratorViewModel {
    func retrievePreferences() {
        let prefs = datasource.getPreferences()
        wordCount = Double(prefs.wordCount)
        separator = prefs.separator
        includeNumbers = prefs.includeNumbers
        capitalize = prefs.capitalize
        leetspeak = prefs.leetspeak
        includeAdjectives = prefs.includeAdjectives
        includeNouns = prefs.includeNouns
        includeVerbs = prefs.includeVerbs
    }
}
