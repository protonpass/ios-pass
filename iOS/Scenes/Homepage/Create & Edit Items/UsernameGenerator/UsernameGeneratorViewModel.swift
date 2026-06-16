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

import Entities
import FactoryKit
import Foundation

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

    @ObservationIgnored
    @LazyInjected(\SharedUseCasesContainer.generateUsername)
    private var generateUsername

    @ObservationIgnored
    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private var router

    @ObservationIgnored
    @LazyInjected(\SharedRepositoryContainer.localUsernamePreferencesDatasource)
    private var datasource

    init() {
        retrievePreferences()
        startTracking()
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
            router.display(element: .displayErrorBanner(error))
        }
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

    func startTracking() {
        withObservationTracking {
            storePreferences()
            regenerate()
        } onChange: { [weak self] in
            guard let self else { return }
            MainActor.assumeIsolated {
                startTracking()
            }
        }
    }

    func storePreferences() {
        datasource.save(preferences: .init(wordCount: Int(wordCount),
                                           separator: separator,
                                           includeNumbers: includeNumbers,
                                           capitalize: capitalize,
                                           leetspeak: leetspeak,
                                           includeAdjectives: includeAdjectives,
                                           includeNouns: includeNouns,
                                           includeVerbs: includeVerbs))
    }
}
