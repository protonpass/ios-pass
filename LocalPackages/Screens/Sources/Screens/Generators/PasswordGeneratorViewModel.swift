//
// PasswordGeneratorViewModel.swift
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

import Client
import Core
import Entities
import Foundation
import UseCases

public extension PasswordGeneratorViewModel {
    final class Factory {
        private let datasource: any LocalPasswordPreferencesDatasourceProtocol
        private let generatePassword: any GeneratePasswordUseCase
        private let generateRandomWords: any GenerateRandomWordsUseCase
        private let generatePassphrase: any GeneratePassphraseUseCase
        private let scorePassword: any ScorePasswordUseCase
        private let getOrganizationSettings: any GetOrganizationSettingsUseCase
        private let passwordHistoryRepository: any PasswordHistoryRepositoryProtocol
        private let logManager: any LogManagerProtocol

        public init(datasource: any LocalPasswordPreferencesDatasourceProtocol,
                    generatePassword: any GeneratePasswordUseCase,
                    generateRandomWords: any GenerateRandomWordsUseCase,
                    generatePassphrase: any GeneratePassphraseUseCase,
                    scorePassword: any ScorePasswordUseCase,
                    getOrganizationSettings: any GetOrganizationSettingsUseCase,
                    passwordHistoryRepository: any PasswordHistoryRepositoryProtocol,
                    logManager: any LogManagerProtocol) {
            self.datasource = datasource
            self.generatePassword = generatePassword
            self.generateRandomWords = generateRandomWords
            self.generatePassphrase = generatePassphrase
            self.scorePassword = scorePassword
            self.getOrganizationSettings = getOrganizationSettings
            self.passwordHistoryRepository = passwordHistoryRepository
            self.logManager = logManager
        }

        public func create(mode: PasswordGeneratorMode,
                           onResult: @escaping (Result<String, any Error>) -> Void) -> PasswordGeneratorViewModel {
            .init(mode: mode,
                  datasource: datasource,
                  generatePassword: generatePassword,
                  generateRandomWords: generateRandomWords,
                  generatePassphrase: generatePassphrase,
                  scorePassword: scorePassword,
                  getOrganizationSettings: getOrganizationSettings,
                  passwordHistoryRepository: passwordHistoryRepository,
                  logManager: logManager,
                  onResult: onResult)
        }
    }
}

@MainActor
@Observable
public final class PasswordGeneratorViewModel {
    private(set) var password = ""
    private(set) var strength: PasswordStrength = .vulnerable

    var passwordType: PasswordType = .memorable

    /// Random password options
    var characterCount: Double = 20
    var hasSpecialCharacters = true
    var hasCapitalCharacters = true
    var hasNumberCharacters = true

    /// Memorable password options
    var wordSeparator: WordSeparator = .hyphens
    var wordCount: Double = 5
    var capitalizingWords = true
    var includingNumbers = true

    /// Boundaries, possibly tightened by the organisation password policy
    private(set) var minChar = Double(PasswordPreferences.minCharCount)
    private(set) var maxChar = Double(PasswordPreferences.maxCharCount)
    private(set) var minWord = Double(PasswordPreferences.minWordCount)
    private(set) var maxWord = Double(PasswordPreferences.maxWordCount)

    var showAdvancedOptions = false
    private(set) var shouldDisplayTypeSelection = true

    var preferences: PasswordPreferences {
        .init(passwordType: passwordType,
              characterCount: Int(characterCount),
              hasSpecialCharacters: hasSpecialCharacters,
              hasCapitalCharacters: hasCapitalCharacters,
              hasNumberCharacters: hasNumberCharacters,
              wordSeparator: wordSeparator,
              wordCount: Int(wordCount),
              capitalizingWords: capitalizingWords,
              includingNumbers: includingNumbers)
    }

    @ObservationIgnored
    let mode: PasswordGeneratorMode

    @ObservationIgnored
    private var cachedWords = [String]()

    @ObservationIgnored
    private var lastGeneratedWordCount: Int?

    @ObservationIgnored
    private var qaPasswordPolicyOverride: Bool {
        UserDefaults.standard.bool(forKey: Constants.QA.forcePasswordPolicy)
    }

    @ObservationIgnored
    private let datasource: any LocalPasswordPreferencesDatasourceProtocol

    @ObservationIgnored
    private let generatePassword: any GeneratePasswordUseCase

    @ObservationIgnored
    private let generateRandomWords: any GenerateRandomWordsUseCase

    @ObservationIgnored
    private let generatePassphrase: any GeneratePassphraseUseCase

    @ObservationIgnored
    private let scorePassword: any ScorePasswordUseCase

    @ObservationIgnored
    private let getOrganizationSettings: any GetOrganizationSettingsUseCase

    @ObservationIgnored
    private let passwordHistoryRepository: any PasswordHistoryRepositoryProtocol

    @ObservationIgnored
    private let logger: Logger

    @ObservationIgnored
    private let onResult: (Result<String, any Error>) -> Void

    init(mode: PasswordGeneratorMode,
         datasource: any LocalPasswordPreferencesDatasourceProtocol,
         generatePassword: any GeneratePasswordUseCase,
         generateRandomWords: any GenerateRandomWordsUseCase,
         generatePassphrase: any GeneratePassphraseUseCase,
         scorePassword: any ScorePasswordUseCase,
         getOrganizationSettings: any GetOrganizationSettingsUseCase,
         passwordHistoryRepository: any PasswordHistoryRepositoryProtocol,
         logManager: any LogManagerProtocol,
         onResult: @escaping (Result<String, any Error>) -> Void) {
        self.mode = mode
        self.datasource = datasource
        self.generatePassword = generatePassword
        self.generateRandomWords = generateRandomWords
        self.generatePassphrase = generatePassphrase
        self.scorePassword = scorePassword
        self.getOrganizationSettings = getOrganizationSettings
        self.passwordHistoryRepository = passwordHistoryRepository
        logger = .init(manager: logManager)
        self.onResult = onResult

        retrievePreferences()
        startTracking()
    }

    func persistAndRegenerate() {
        datasource.save(preferences: preferences)
        regenerate()
    }

    func regenerate(forceRefresh: Bool = true) {
        do {
            let newPassword: String
            switch passwordType {
            case .random:
                newPassword = try generatePassword(length: Int(characterCount),
                                                   numbers: hasNumberCharacters,
                                                   uppercaseLetters: hasCapitalCharacters,
                                                   symbols: hasSpecialCharacters)

            case .memorable:
                let wordCount = Int(wordCount)
                if forceRefresh || cachedWords.isEmpty || wordCount != lastGeneratedWordCount {
                    cachedWords = try generateRandomWords(wordCount: wordCount)
                    lastGeneratedWordCount = wordCount
                }
                newPassword = try generatePassphrase(words: cachedWords,
                                                     separator: wordSeparator,
                                                     capitalise: capitalizingWords,
                                                     includeNumbers: includingNumbers)
            }
            password = newPassword
            let score = scorePassword(newPassword)
            strength = score.strength
        } catch {
            onResult(.failure(error))
        }
    }

    func saveHistory(onComplete: @escaping (String) -> Void) {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await passwordHistoryRepository.insertPassword(password)
                onComplete(password)
            } catch {
                onResult(.failure(error))
            }
        }
    }

    func checkForOrganisationLimitation() async {
        do {
            if let settings = try await getOrganizationSettings() {
                let passwordPolicy: PasswordPolicy? = if qaPasswordPolicyOverride,
                                                         let string = UserDefaults.standard
                                                         .string(forKey: Constants.QA.passwordPolicy) {
                    PasswordPolicy(rawValue: string)
                } else if let newPasswordPolicy = settings.passwordPolicy {
                    newPasswordPolicy
                } else {
                    nil
                }

                if let passwordPolicy {
                    apply(policy: passwordPolicy)
                }
            }
        } catch {
            logger.error(error)
        }
    }
}

private extension PasswordGeneratorViewModel {
    func startTracking() {
        withObservationTracking {
            storePreferences()
            regenerate(forceRefresh: false)
        } onChange: { [weak self] in
            guard let self else { return }
            MainActor.assumeIsolated {
                startTracking()
            }
        }
    }

    func retrievePreferences() {
        let prefs = datasource.getPreferences()
        passwordType = prefs.passwordType
        characterCount = Double(prefs.characterCount)
        hasSpecialCharacters = prefs.hasSpecialCharacters
        hasCapitalCharacters = prefs.hasCapitalCharacters
        hasNumberCharacters = prefs.hasNumberCharacters
        wordSeparator = prefs.wordSeparator
        wordCount = Double(prefs.wordCount)
        capitalizingWords = prefs.capitalizingWords
        includingNumbers = prefs.includingNumbers
    }

    func storePreferences() {
        datasource.save(preferences: .init(passwordType: passwordType,
                                           characterCount: Int(characterCount),
                                           hasSpecialCharacters: hasSpecialCharacters,
                                           hasCapitalCharacters: hasCapitalCharacters,
                                           hasNumberCharacters: hasNumberCharacters,
                                           wordSeparator: wordSeparator,
                                           wordCount: Int(wordCount),
                                           capitalizingWords: capitalizingWords,
                                           includingNumbers: includingNumbers))
    }

    func apply(policy: PasswordPolicy) {
        if !policy.randomPasswordAllowed {
            passwordType = .memorable
        }

        if !policy.memorablePasswordAllowed, passwordType == .memorable {
            passwordType = .random
        }

        shouldDisplayTypeSelection = policy.randomPasswordAllowed && policy.memorablePasswordAllowed

        minChar = Double(policy.randomPasswordMinLength)
        maxChar = Double(policy.randomPasswordMaxLength)

        characterCount = adjustToRange(characterCount, range: minChar...maxChar)

        if let randomPasswordMustIncludeSymbols = policy.randomPasswordMustIncludeSymbols {
            hasSpecialCharacters = randomPasswordMustIncludeSymbols
        }

        if let randomPasswordMustIncludeUppercase = policy.randomPasswordMustIncludeUppercase {
            hasCapitalCharacters = randomPasswordMustIncludeUppercase
        }

        if let randomPasswordMustIncludeNumbers = policy.randomPasswordMustIncludeNumbers {
            hasNumberCharacters = randomPasswordMustIncludeNumbers
        }

        minWord = Double(policy.memorablePasswordMinWords)
        maxWord = Double(policy.memorablePasswordMaxWords)

        wordCount = adjustToRange(wordCount, range: minWord...maxWord)

        if let memorablePasswordMustCapitalize = policy.memorablePasswordMustCapitalize {
            capitalizingWords = memorablePasswordMustCapitalize
        }

        if let memorablePasswordMustIncludeNumbers = policy.memorablePasswordMustIncludeNumbers {
            includingNumbers = memorablePasswordMustIncludeNumbers
        }

        if !includingNumbers, wordSeparator == .numbersAndSymbols || wordSeparator == .numbers {
            wordSeparator = .commas
        }
    }

    func adjustToRange(_ number: Double, range: ClosedRange<Double>) -> Double {
        if range.contains(number) {
            number
        } else if number < range.lowerBound {
            range.lowerBound
        } else {
            range.upperBound
        }
    }
}
