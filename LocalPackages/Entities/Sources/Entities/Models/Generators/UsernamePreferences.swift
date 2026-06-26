//
// UsernamePreferences.swift
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

public struct UsernamePreferences: Sendable {
    public let wordCount: Int
    public let separator: WordSeparator
    public let includeNumbers: Bool
    public let capitalize: Bool
    public let leetspeak: Bool
    public let includeAdjectives: Bool
    public let includeNouns: Bool
    public let includeVerbs: Bool

    public static let minWordCount = 1
    public static let maxWordCount = 5

    public static var `default`: Self {
        .init(wordCount: 2,
              separator: .hyphens,
              includeNumbers: true,
              capitalize: false,
              leetspeak: false,
              includeAdjectives: true,
              includeNouns: true,
              includeVerbs: false)
    }

    public init(wordCount: Int,
                separator: WordSeparator,
                includeNumbers: Bool,
                capitalize: Bool,
                leetspeak: Bool,
                includeAdjectives: Bool,
                includeNouns: Bool,
                includeVerbs: Bool) {
        self.wordCount = wordCount
        self.separator = separator
        self.includeNumbers = includeNumbers
        self.capitalize = capitalize
        self.leetspeak = leetspeak
        self.includeAdjectives = includeAdjectives
        self.includeNouns = includeNouns
        self.includeVerbs = includeVerbs
    }
}
