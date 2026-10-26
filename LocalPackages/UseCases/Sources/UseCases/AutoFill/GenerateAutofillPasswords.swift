//
// GenerateAutofillPasswords.swift
// Proton Pass - Created on 24/06/2026.
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

// sourcery: AutoMockable
public protocol GenerateAutofillPasswordsUseCase: Sendable {
    /// Site `rules` are ignored when they contradict the organization's password policy.
    func callAsFunction(rules: PasswordRules?) async throws -> [GeneratedPassword]
}

public struct GenerateAutofillPasswords: GenerateAutofillPasswordsUseCase {
    private let generatePassword: any GeneratePasswordUseCase
    private let generateRandomWords: any GenerateRandomWordsUseCase
    private let generatePassphrase: any GeneratePassphraseUseCase
    private let generateRuleCompliantPassword: any GenerateRuleCompliantPasswordUseCase
    private let resolvePasswordPolicy: any ResolvePasswordPolicyUseCase
    private let getOrganizationSettings: any GetOrganizationSettingsUseCase
    private let localDataSource: any LocalPasswordPreferencesDatasourceProtocol
    private let logger: Logger

    public init(generatePassword: any GeneratePasswordUseCase,
                generateRandomWords: any GenerateRandomWordsUseCase,
                generatePassphrase: any GeneratePassphraseUseCase,
                generateRuleCompliantPassword: any GenerateRuleCompliantPasswordUseCase,
                resolvePasswordPolicy: any ResolvePasswordPolicyUseCase,
                getOrganizationSettings: any GetOrganizationSettingsUseCase,
                localDataSource: any LocalPasswordPreferencesDatasourceProtocol,
                logManager: any LogManagerProtocol) {
        self.generatePassword = generatePassword
        self.generateRandomWords = generateRandomWords
        self.generatePassphrase = generatePassphrase
        self.generateRuleCompliantPassword = generateRuleCompliantPassword
        self.resolvePasswordPolicy = resolvePasswordPolicy
        self.getOrganizationSettings = getOrganizationSettings
        self.localDataSource = localDataSource
        logger = .init(manager: logManager)
    }

    public func callAsFunction(rules: PasswordRules?) async throws -> [GeneratedPassword] {
        let policy = await passwordPolicy()
        let preferences = preferences(applying: policy)
        let organizationRules = policy.map(PasswordRules.init(randomPasswordPolicy:)) ?? PasswordRules()
        let combinedRules = rules?.intersected(with: organizationRules)
        let siteRules = combinedRules == nil ? nil : rules
        let randomRules: PasswordRules? = if policy?.randomPasswordAllowed == false {
            nil
        } else {
            combinedRules ?? organizationRules
        }

        let strong = try randomPassword(kind: .strong,
                                        rules: randomRules,
                                        hasSiteRules: siteRules != nil,
                                        preferences: preferences)
        let alphanumeric = try randomPassword(kind: .alphanumeric,
                                              rules: randomRules,
                                              hasSiteRules: siteRules != nil,
                                              preferences: preferences)
        let passphrase = try policy?.memorablePasswordAllowed == false
            ? nil
            : memorablePassword(preferences: preferences, siteRules: siteRules)

        let suggestions = switch preferences.passwordType {
        case .memorable: [passphrase, strong, alphanumeric]
        case .random: [strong, passphrase, alphanumeric]
        }
        return suggestions.compactMap(\.self)
    }
}

private extension GenerateAutofillPasswords {
    func passwordPolicy() async -> PasswordPolicy? {
        do {
            return try await getOrganizationSettings()?.passwordPolicy
        } catch {
            // Fails open like the in-app generator, rather than blocking password generation
            logger.error(error)
            return nil
        }
    }

    func preferences(applying policy: PasswordPolicy?) -> PasswordPreferences {
        let stored = localDataSource.getPreferences()
        let defaults = PasswordPreferences.default
        // AutoFill always suggests strong passwords, whatever was last picked in the in-app generator
        let preferences = PasswordPreferences(passwordType: stored.passwordType,
                                              characterCount: max(stored.characterCount,
                                                                  defaults.characterCount),
                                              hasSpecialCharacters: true,
                                              hasCapitalCharacters: true,
                                              hasNumberCharacters: true,
                                              wordSeparator: stored.wordSeparator,
                                              wordCount: max(stored.wordCount, defaults.wordCount),
                                              capitalizingWords: true,
                                              includingNumbers: true)
        guard let policy else { return preferences }
        return resolvePasswordPolicy(preferences: preferences, policy: policy).preferences
    }

    /// Without site rules, the Rust generator is used: the resolved preferences already express the
    /// organization policy through its options.
    func randomPassword(kind: GeneratedPassword.Kind,
                        rules: PasswordRules?,
                        hasSiteRules: Bool,
                        preferences: PasswordPreferences) throws -> GeneratedPassword? {
        let symbols = kind == .strong
        let kindRules: PasswordRules = symbols ? .requiringSpecial : .alphanumeric
        guard let rules = rules?.intersected(with: kindRules) else { return nil }

        if hasSiteRules {
            return generateRuleCompliantPassword(rules: rules, preferredLength: preferences.characterCount)
                .map { .init(kind: kind, value: $0) }
        }
        let value = try generatePassword(length: preferences.characterCount,
                                         numbers: preferences.hasNumberCharacters,
                                         uppercaseLetters: preferences.hasCapitalCharacters,
                                         symbols: symbols)
        return .init(kind: kind, value: value)
    }

    func memorablePassword(preferences: PasswordPreferences,
                           siteRules: PasswordRules?) throws -> GeneratedPassword? {
        let words = try generateRandomWords(wordCount: preferences.wordCount)
        let passphrase = try generatePassphrase(words: words,
                                                separator: preferences.wordSeparator,
                                                capitalise: preferences.capitalizingWords,
                                                includeNumbers: preferences.includingNumbers)
        if let siteRules, !siteRules.isSatisfied(by: passphrase) {
            return nil
        }
        return .init(kind: .passphrase, value: passphrase)
    }
}

private extension PasswordRules {
    static let requiringSpecial = PasswordRules(requiredSets: [CharacterClass.special.characters])

    static let alphanumeric = PasswordRules(allowed: CharacterClass.upper.characters
        .union(CharacterClass.lower.characters)
        .union(CharacterClass.digit.characters))
}
