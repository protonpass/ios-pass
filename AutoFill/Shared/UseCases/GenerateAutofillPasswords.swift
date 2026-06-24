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
import Core
import Entities
import UseCases

// sourcery: AutoMockable
@available(iOS 26.2, *)
public protocol GenerateAutofillPasswordsUseCase: Sendable {
    func callAsFunction() throws -> [ASGeneratedPassword]
}

@available(iOS 26.2, *)
public struct GenerateAutofillPasswords: GenerateAutofillPasswordsUseCase {
    private let generatePassword: any GeneratePasswordUseCase
    private let generateRandomWords: any GenerateRandomWordsUseCase
    private let generatePassphrase: any GeneratePassphraseUseCase

    init(generatePassword: any GeneratePasswordUseCase,
         generateRandomWords: any GenerateRandomWordsUseCase,
         generatePassphrase: any GeneratePassphraseUseCase) {
        self.generatePassword = generatePassword
        self.generateRandomWords = generateRandomWords
        self.generatePassphrase = generatePassphrase
    }

    public func callAsFunction() throws -> [ASGeneratedPassword] {
        let characterCount = kSharedUserDefaults.object(forKey: "characterCount") as? Int ?? 20
        let hasSpecialCharacters = kSharedUserDefaults.object(forKey: "hasSpecialCharacters") as? Bool ?? true
        let hasCapitalCharacters = kSharedUserDefaults.object(forKey: "hasCapitalCharacters") as? Bool ?? true
        let hasNumberCharacters = kSharedUserDefaults.object(forKey: "hasNumberCharacters") as? Bool ?? true
        let wordCount = kSharedUserDefaults.object(forKey: "wordCount") as? Int ?? 5
        let capitalizingWords = kSharedUserDefaults.object(forKey: "capitalizingWords") as? Bool ?? true
        let includingNumbers = kSharedUserDefaults.object(forKey: "includingNumbers") as? Bool ?? true
        let wordSeparatorRawValue = kSharedUserDefaults.object(forKey: "wordSeparator") as? Int
        let wordSeparator = wordSeparatorRawValue.flatMap { WordSeparator(rawValue: $0) } ?? .hyphens
        let rawValue = kSharedUserDefaults.integer(forKey: "passwordType")
        let passwordType = PasswordType(rawValue: rawValue)

        var results = [ASGeneratedPassword]()

        // Strong password (with special characters)
        let strongPassword = try generatePassword(length: characterCount,
                                                  numbers: hasNumberCharacters,
                                                  uppercaseLetters: hasCapitalCharacters,
                                                  symbols: hasSpecialCharacters)

        // Alphanumeric password (no special characters)
        let alphanumericPassword = try generatePassword(length: characterCount,
                                                        numbers: true,
                                                        uppercaseLetters: true,
                                                        symbols: false)

        // Passphrase
        let words = try generateRandomWords(wordCount: wordCount)
        let passphrase = try generatePassphrase(words: words,
                                                separator: wordSeparator,
                                                capitalise: capitalizingWords,
                                                includeNumbers: includingNumbers)
        results.append(ASGeneratedPassword(kind: .passphrase, value: passphrase))

        if passwordType == .memorable {
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
