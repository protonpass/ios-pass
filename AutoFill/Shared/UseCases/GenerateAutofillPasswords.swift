//
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
//

import AuthenticationServices
import Client
import Core
import DIComposition
import Entities
import UseCases

protocol GenerateAutofillPasswordsUseCase: Sendable {
    @available(iOS 26.2, *)
    func callAsFunction() throws -> [ASGeneratedPassword]
}

struct GenerateAutofillPasswords: GenerateAutofillPasswordsUseCase {
    private let generatePassword: any GeneratePasswordUseCase
    private let generateRandomWords: any GenerateRandomWordsUseCase
    private let generatePassphrase: any GeneratePassphraseUseCase
    private let localDataSource: any LocalPasswordPreferencesDatasourceProtocol

    init(generatePassword: any GeneratePasswordUseCase,
         generateRandomWords: any GenerateRandomWordsUseCase,
         generatePassphrase: any GeneratePassphraseUseCase,
         localDataSource: any LocalPasswordPreferencesDatasourceProtocol) {
        self.generatePassword = generatePassword
        self.generateRandomWords = generateRandomWords
        self.generatePassphrase = generatePassphrase
        self.localDataSource = localDataSource
    }

    @available(iOS 26.2, *)
    func callAsFunction() throws -> [ASGeneratedPassword] {
        let preference = localDataSource.getPreferences()

        let characterCount = max(preference.characterCount, PasswordPreferences.default.characterCount)
        // Strong password (with special characters)
        let strongPassword = try generatePassword(length: characterCount,
                                                  numbers: true,
                                                  uppercaseLetters: true,
                                                  symbols: true)

        // Alphanumeric password (no special characters)
        let alphanumericPassword = try generatePassword(length: characterCount,
                                                        numbers: true,
                                                        uppercaseLetters: true,
                                                        symbols: false)

        // Passphrase
        let wordCount = max(preference.wordCount, PasswordPreferences.default.wordCount)
        let words = try generateRandomWords(wordCount: wordCount)

        let passphrase = try generatePassphrase(words: words,
                                                separator: preference.wordSeparator,
                                                capitalise: true,
                                                includeNumbers: true)
        var results = [ASGeneratedPassword]()
        results.append(ASGeneratedPassword(kind: .passphrase, value: passphrase))

        if preference.passwordType == .memorable {
            results.append(ASGeneratedPassword(kind: .passphrase, value: passphrase))
            results.append(ASGeneratedPassword(kind: .strong, value: strongPassword))
        } else {
            results.append(ASGeneratedPassword(kind: .strong, value: strongPassword))
            results.append(ASGeneratedPassword(kind: .passphrase, value: passphrase))
        }

        results.append(ASGeneratedPassword(kind: .alphanumeric, value: alphanumericPassword))
        return results
    }
}
