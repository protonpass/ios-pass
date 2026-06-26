//
// PasswordPreferences.swift
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

import Foundation

public struct PasswordPreferences: Sendable {
    public let passwordType: PasswordType

    // Random password options
    public let characterCount: Int
    public let hasSpecialCharacters: Bool
    public let hasCapitalCharacters: Bool
    public let hasNumberCharacters: Bool

    // Memorable password options
    public let wordSeparator: WordSeparator
    public let wordCount: Int
    public let capitalizingWords: Bool
    public let includingNumbers: Bool

    public static let minCharCount = 4
    public static let maxCharCount = 64
    public static let minWordCount = 1
    public static let maxWordCount = 10

    public static var `default`: Self {
        .init(passwordType: .memorable,
              characterCount: 20,
              hasSpecialCharacters: true,
              hasCapitalCharacters: true,
              hasNumberCharacters: true,
              wordSeparator: .hyphens,
              wordCount: 5,
              capitalizingWords: true,
              includingNumbers: true)
    }

    public init(passwordType: PasswordType,
                characterCount: Int,
                hasSpecialCharacters: Bool,
                hasCapitalCharacters: Bool,
                hasNumberCharacters: Bool,
                wordSeparator: WordSeparator,
                wordCount: Int,
                capitalizingWords: Bool,
                includingNumbers: Bool) {
        self.passwordType = passwordType
        self.characterCount = characterCount
        self.hasSpecialCharacters = hasSpecialCharacters
        self.hasCapitalCharacters = hasCapitalCharacters
        self.hasNumberCharacters = hasNumberCharacters
        self.wordSeparator = wordSeparator
        self.wordCount = wordCount
        self.capitalizingWords = capitalizingWords
        self.includingNumbers = includingNumbers
    }
}
