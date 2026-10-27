//
// GenerateAutofillPasswordsTests.swift
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

import Client
import CoreMocks
import Entities
import Foundation
import Testing
import UseCases

@Suite(.tags(.useCase))
struct GenerateAutofillPasswordsTests {
    // MARK: - Without site rules

    @Test func `without rules or policy every kind comes from rust in the memorable order`() async throws {
        let suggestions = try await makeSut()(rules: nil)

        #expect(suggestions == [
            .init(kind: .passphrase, value: "Word0-Word1-Word2-Word3-Word4-1"),
            .init(kind: .strong, value: "random:20:numbers:uppercase:symbols"),
            .init(kind: .alphanumeric, value: "random:20:numbers:uppercase")
        ])
    }

    @Test func `the random password type puts the strong password first`() async throws {
        let suggestions = try await makeSut(preferences: preferences(type: .random))(rules: nil)

        #expect(suggestions.map(\.kind) == [.strong, .passphrase, .alphanumeric])
    }

    @Test func `short stored lengths are raised to the defaults`() async throws {
        let sut = makeSut(preferences: preferences(characterCount: 8, wordCount: 2))

        let suggestions = try await sut(rules: nil)

        #expect(suggestions.first { $0.kind == .strong }?.value == "random:20:numbers:uppercase:symbols")
        #expect(suggestions.first { $0.kind == .passphrase }?.value == "Word0-Word1-Word2-Word3-Word4-1")
    }

    // MARK: - Site rules

    @Test func `site rules shape the random passwords and drop a non compliant passphrase`() async throws {
        let rules =
            try #require(PasswordRules("minlength: 8; maxlength: 12; required: digit; allowed: lower, [-_]"))

        let suggestions = try await makeSut()(rules: rules)

        try #require(suggestions.map(\.kind) == [.strong, .alphanumeric])
        for suggestion in suggestions {
            #expect(rules.isSatisfied(by: suggestion.value))
        }
        #expect(suggestions[0].value.contains { "-_".contains($0) })
        #expect(!suggestions[1].value.contains { "-_".contains($0) })
    }

    @Test func `a site requiring special characters gets no alphanumeric password`() async throws {
        let rules = try #require(PasswordRules("required: [-!@#]; allowed: lower, upper, digit"))

        let suggestions = try await makeSut()(rules: rules)

        try #require(suggestions.map(\.kind) == [.passphrase, .strong])
        #expect(suggestions[1].value.contains { "-!@#".contains($0) })
    }

    @Test func `a site without special characters only gets an alphanumeric password`() async throws {
        let rules = try #require(PasswordRules("allowed: lower, upper, digit"))

        let suggestions = try await makeSut()(rules: rules)

        #expect(suggestions.map(\.kind) == [.alphanumeric])
    }

    @Test func `a compliant passphrase is kept`() async throws {
        let rules = try #require(PasswordRules("allowed: lower, upper, digit, [-]"))

        let suggestions = try await makeSut()(rules: rules)

        #expect(suggestions.first?.value == "Word0-Word1-Word2-Word3-Word4-1")
    }

    // MARK: - Organization policy

    @Test func `a policy disallowing random passwords only offers a passphrase`() async throws {
        let sut = makeSut(policy: policy(randomAllowed: false))

        let suggestions = try await sut(rules: nil)

        #expect(suggestions.map(\.kind) == [.passphrase])
    }

    @Test func `a policy disallowing memorable passwords only offers random ones`() async throws {
        let sut = makeSut(policy: policy(memorableAllowed: false))

        let suggestions = try await sut(rules: nil)

        #expect(suggestions.map(\.kind) == [.strong, .alphanumeric])
    }

    @Test(arguments: [
        (true, [GeneratedPassword.Kind.passphrase, .strong]),
        (false, [.passphrase, .alphanumeric])
    ])
    func `the policy symbols flag picks the random kinds`(mustIncludeSymbols: Bool,
                                                          expected: [GeneratedPassword
                                                              .Kind]) async throws {
        let sut = makeSut(policy: policy(symbols: mustIncludeSymbols))

        let suggestions = try await sut(rules: nil)

        #expect(suggestions.map(\.kind) == expected)
    }

    @Test func `policy bounds and flags reach the rust generator`() async throws {
        let sut = makeSut(policy: policy(minLength: 30, numbers: false))

        let suggestions = try await sut(rules: nil)

        #expect(suggestions.first { $0.kind == .strong }?.value == "random:30:uppercase:symbols")
    }

    @Test func `site rules contradicting the policy are ignored`() async throws {
        let rules = try #require(PasswordRules("maxlength: 12"))
        let sut = makeSut(policy: policy(minLength: 20))

        let suggestions = try await sut(rules: rules)

        #expect(suggestions == [
            .init(kind: .passphrase, value: "Word0-Word1-Word2-Word3-Word4-1"),
            .init(kind: .strong, value: "random:20:numbers:uppercase:symbols"),
            .init(kind: .alphanumeric, value: "random:20:numbers:uppercase")
        ])
    }

    @Test func `site rules are narrowed by the policy`() async throws {
        let rules = try #require(PasswordRules("minlength: 8; maxlength: 16"))
        let sut = makeSut(policy: policy(numbers: false))

        let suggestions = try await sut(rules: rules)

        let random = suggestions.filter { $0.kind != .passphrase }
        #expect(random.map(\.kind) == [.strong, .alphanumeric])
        for suggestion in random {
            #expect(rules.isSatisfied(by: suggestion.value))
            #expect(!suggestion.value.contains { $0.isNumber })
        }
    }

    @Test func `a failing policy lookup generates as if there were no policy`() async throws {
        let sut = makeSut(organizationSettings: .failure(URLError(.notConnectedToInternet)))

        let suggestions = try await sut(rules: nil)

        #expect(suggestions.map(\.kind) == [.passphrase, .strong, .alphanumeric])
    }
}

private extension GenerateAutofillPasswordsTests {
    func makeSut(preferences: PasswordPreferences = .default,
                 policy: PasswordPolicy? = nil) -> GenerateAutofillPasswords {
        makeSut(preferences: preferences, organizationSettings: .success(policy.map(settings)))
    }

    func makeSut(preferences: PasswordPreferences = .default,
                 organizationSettings: Result<Organization.Settings?, any Error>) -> GenerateAutofillPasswords {
        GenerateAutofillPasswords(generatePassword: GeneratePasswordStub(),
                                  generateRandomWords: GenerateRandomWordsStub(),
                                  generatePassphrase: GeneratePassphraseStub(),
                                  generateRuleCompliantPassword: GenerateRuleCompliantPassword(),
                                  resolvePasswordPolicy: ResolvePasswordPolicy(),
                                  getOrganizationSettings: OrganizationSettingsStub(result: organizationSettings),
                                  localDataSource: PasswordPreferencesStub(preferences: preferences),
                                  logManager: LogManagerProtocolMock())
    }

    func preferences(type: PasswordType = .memorable,
                     characterCount: Int = 20,
                     wordCount: Int = 5) -> PasswordPreferences {
        let defaults = PasswordPreferences.default
        return PasswordPreferences(passwordType: type,
                                   characterCount: characterCount,
                                   hasSpecialCharacters: defaults.hasSpecialCharacters,
                                   hasCapitalCharacters: defaults.hasCapitalCharacters,
                                   hasNumberCharacters: defaults.hasNumberCharacters,
                                   wordSeparator: defaults.wordSeparator,
                                   wordCount: wordCount,
                                   capitalizingWords: defaults.capitalizingWords,
                                   includingNumbers: defaults.includingNumbers)
    }

    func policy(randomAllowed: Bool = true,
                memorableAllowed: Bool = true,
                minLength: Int = 4,
                numbers: Bool? = nil,
                symbols: Bool? = nil) -> PasswordPolicy {
        PasswordPolicy(randomPasswordAllowed: randomAllowed,
                       randomPasswordMinLength: minLength,
                       randomPasswordMaxLength: 64,
                       randomPasswordMustIncludeNumbers: numbers,
                       randomPasswordMustIncludeSymbols: symbols,
                       randomPasswordMustIncludeUppercase: nil,
                       memorablePasswordAllowed: memorableAllowed,
                       memorablePasswordMinWords: nil,
                       memorablePasswordMaxWords: nil,
                       memorablePasswordMustCapitalize: nil,
                       memorablePasswordMustIncludeNumbers: nil)
    }

    func settings(_ policy: PasswordPolicy) -> Organization.Settings {
        Organization.Settings(shareMode: .unrestricted,
                              itemShareMode: .enabled,
                              publicLinkMode: .enabled,
                              forceLockSeconds: 0,
                              exportMode: .anyone,
                              passwordPolicy: policy,
                              vaultCreateMode: nil,
                              aliasCreateMode: nil)
    }
}

/// Encodes its inputs in the output so tests can tell how the Rust generator was called.
private struct GeneratePasswordStub: GeneratePasswordUseCase {
    func execute(length: Int, numbers: Bool, uppercaseLetters: Bool, symbols: Bool) throws -> String {
        (["random:\(length)"] + [
            numbers ? "numbers" : nil,
            uppercaseLetters ? "uppercase" : nil,
            symbols ? "symbols" : nil
        ].compactMap(\.self))
            .joined(separator: ":")
    }
}

private struct GenerateRandomWordsStub: GenerateRandomWordsUseCase {
    func execute(wordCount: Int) throws -> [String] {
        (0..<wordCount).map { "word\($0)" }
    }
}

private struct GeneratePassphraseStub: GeneratePassphraseUseCase {
    func execute(words: [String], separator: WordSeparator, capitalise: Bool,
                 includeNumbers: Bool) throws -> String {
        let words = capitalise ? words.map(\.capitalized) : words
        return (words + (includeNumbers ? ["1"] : [])).joined(separator: "-")
    }
}

private struct OrganizationSettingsStub: GetOrganizationSettingsUseCase {
    let result: Result<Organization.Settings?, any Error>

    func execute() async throws -> Organization.Settings? {
        try result.get()
    }
}

private struct PasswordPreferencesStub: LocalPasswordPreferencesDatasourceProtocol {
    let preferences: PasswordPreferences

    func save(preferences: PasswordPreferences) {}

    func getPreferences() -> PasswordPreferences {
        preferences
    }
}
