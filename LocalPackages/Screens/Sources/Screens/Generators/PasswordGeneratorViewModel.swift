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
        private let resolvePasswordPolicy: any ResolvePasswordPolicyUseCase
        private let logManager: any LogManagerProtocol

        public init(datasource: any LocalPasswordPreferencesDatasourceProtocol,
                    generatePassword: any GeneratePasswordUseCase,
                    generateRandomWords: any GenerateRandomWordsUseCase,
                    generatePassphrase: any GeneratePassphraseUseCase,
                    scorePassword: any ScorePasswordUseCase,
                    getOrganizationSettings: any GetOrganizationSettingsUseCase,
                    passwordHistoryRepository: any PasswordHistoryRepositoryProtocol,
                    resolvePasswordPolicy: any ResolvePasswordPolicyUseCase,
                    logManager: any LogManagerProtocol) {
            self.datasource = datasource
            self.generatePassword = generatePassword
            self.generateRandomWords = generateRandomWords
            self.generatePassphrase = generatePassphrase
            self.scorePassword = scorePassword
            self.getOrganizationSettings = getOrganizationSettings
            self.passwordHistoryRepository = passwordHistoryRepository
            self.resolvePasswordPolicy = resolvePasswordPolicy
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
                  resolvePasswordPolicy: resolvePasswordPolicy,
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
    private(set) var penalties: [PasswordPenalty] = []
    private(set) var showingPenalties: Bool

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
    private(set) var minChar = PasswordPreferences.minCharCount
    private(set) var maxChar = PasswordPreferences.maxCharCount
    private(set) var minWord = PasswordPreferences.minWordCount
    private(set) var maxWord = PasswordPreferences.maxWordCount

    var showingAdvancedOptions = false
    private(set) var shouldDisplayTypeSelection = true

    /// Options whose value is dictated by the organisation policy; their toggles must be read-only.
    private(set) var lockedOptions = PasswordPolicyLockedOptions.unlocked

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
    private var persistTask: Task<Void, Never>?

    /// The preferences produced by the last organisation-policy application. While the live
    /// preferences still equal this value the change came from the policy (or a redundant
    /// re-delivery of the change callback) and must not be persisted; the first genuine user edit
    /// clears it.
    @ObservationIgnored
    private var policyAppliedPreferences: PasswordPreferences?

    @ObservationIgnored
    private var qaPasswordPolicyOverride: Bool {
        UserDefaults.standard.bool(forKey: Constants.QA.forcePasswordPolicy)
    }

    @ObservationIgnored
    private let datasource: any LocalPasswordPreferencesDatasourceProtocol

    @ObservationIgnored
    private let generatePassword: any GeneratePasswordUseCase

    @ObservationIgnored
    private let resolvePasswordPolicy: any ResolvePasswordPolicyUseCase

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
         resolvePasswordPolicy: any ResolvePasswordPolicyUseCase,
         passwordHistoryRepository: any PasswordHistoryRepositoryProtocol,
         logManager: any LogManagerProtocol,
         onResult: @escaping (Result<String, any Error>) -> Void) {
        self.mode = mode
        showingPenalties = mode == .autofill
        self.datasource = datasource
        self.generatePassword = generatePassword
        self.generateRandomWords = generateRandomWords
        self.generatePassphrase = generatePassphrase
        self.scorePassword = scorePassword
        self.getOrganizationSettings = getOrganizationSettings
        self.resolvePasswordPolicy = resolvePasswordPolicy
        self.passwordHistoryRepository = passwordHistoryRepository
        logger = .init(manager: logManager)
        self.onResult = onResult

        retrievePreferences()
        regenerate(forceRefresh: false)
    }

    /// Called on every user-driven preference change. Regenerates immediately for a live preview
    /// (reusing the current words for memorable passwords, so tweaking a formatting option doesn't
    /// draw a brand-new passphrase) and debounces persistence so dragging a slider doesn't write to
    /// disk on every intermediate value.
    func handlePreferenceChange() {
        regenerate(forceRefresh: false)

        // Never persist the policy-clamped values (this callback can be delivered for the policy
        // mutation itself). Any value differing from the policy baseline is a real user edit, which
        // clears the suppression so subsequent edits persist normally.
        if preferences == policyAppliedPreferences {
            return
        }
        policyAppliedPreferences = nil
        schedulePersist()
    }

    func flushPendingPreferences() {
        guard persistTask != nil else { return }
        persistTask?.cancel()
        persistTask = nil
        datasource.save(preferences: preferences)
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
            penalties = score.penalties
        } catch {
            onResult(.failure(error))
        }
    }

    func showPenalties() {
        if !showingPenalties, mode != .autofill {
            showingPenalties = true
        }
    }

    func handleCta() {
        // Strong `self` capture is intentional: the caller dismisses the view immediately after
        // calling this, which releases the view-owned view model. A weak capture could deallocate
        // `self` before `insertPassword` resumes, silently dropping `onResult`. The task is
        // short-lived and self-terminating, so the strong capture cannot leak.
        Task {
            do {
                try await passwordHistoryRepository.insertPassword(password)
                onResult(.success(password))
            } catch {
                onResult(.failure(error))
            }
        }
    }

    func checkForOrganisationLimitation() async {
        do {
            let passwordPolicy: PasswordPolicy? = if qaPasswordPolicyOverride,
                                                     let string = UserDefaults.standard
                                                     .string(forKey: Constants.QA.passwordPolicy) {
                PasswordPolicy(rawValue: string)
            } else if let newPasswordPolicy = try await getOrganizationSettings()?.passwordPolicy {
                newPasswordPolicy
            } else {
                nil
            }

            if let passwordPolicy {
                apply(policy: passwordPolicy)
            }
        } catch {
            logger.error(error)
        }
    }
}

private extension PasswordGeneratorViewModel {
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

    func apply(policy: PasswordPolicy) {
        let resolution = resolvePasswordPolicy(preferences: preferences, policy: policy)
        let resolved = resolution.preferences

        passwordType = resolved.passwordType
        characterCount = Double(resolved.characterCount)
        hasSpecialCharacters = resolved.hasSpecialCharacters
        hasCapitalCharacters = resolved.hasCapitalCharacters
        hasNumberCharacters = resolved.hasNumberCharacters
        wordSeparator = resolved.wordSeparator
        wordCount = Double(resolved.wordCount)
        capitalizingWords = resolved.capitalizingWords
        includingNumbers = resolved.includingNumbers

        minChar = resolution.bounds.minCharacterCount
        maxChar = resolution.bounds.maxCharacterCount
        minWord = resolution.bounds.minWordCount
        maxWord = resolution.bounds.maxWordCount

        shouldDisplayTypeSelection = resolution.allowsTypeSelection
        lockedOptions = resolution.lockedOptions

        policyAppliedPreferences = preferences
    }

    func schedulePersist() {
        persistTask?.cancel()
        persistTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(500))
            guard let self, !Task.isCancelled else { return }
            datasource.save(preferences: preferences)
            persistTask = nil
        }
    }
}
