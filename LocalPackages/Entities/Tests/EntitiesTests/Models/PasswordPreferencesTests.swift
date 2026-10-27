//
// PasswordPreferencesTests.swift
// Proton Pass - Created on 26/10/2026.
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
import Testing

@Suite(.tags(.entity))
struct PasswordPreferencesTests {
    typealias Kind = GeneratedPassword.Kind

    @Test(arguments: [
        (PasswordType.memorable, true, Kind.passphrase),
        (.memorable, false, .passphrase),
        (.random, true, .strong),
        (.random, false, .alphanumeric)
    ])
    func `suggestion kind follows type and special characters`(type: PasswordType, special: Bool, expected: Kind) {
        let preferences = PasswordPreferences(passwordType: type,
                                              characterCount: 20,
                                              hasSpecialCharacters: special,
                                              hasCapitalCharacters: true,
                                              hasNumberCharacters: true,
                                              wordSeparator: .hyphens,
                                              wordCount: 5,
                                              capitalizingWords: true,
                                              includingNumbers: true)

        #expect(preferences.generatedPasswordKind == expected)
    }
}
