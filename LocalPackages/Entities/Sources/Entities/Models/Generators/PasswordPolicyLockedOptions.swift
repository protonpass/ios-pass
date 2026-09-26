//
// PasswordPolicyLockedOptions.swift
// Proton Pass - Created on 06/07/2026.
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

public struct PasswordPolicyLockedOptions: Sendable, Equatable {
    public let specialCharacters: Bool
    public let capitalCharacters: Bool
    public let numberCharacters: Bool
    public let capitalizingWords: Bool
    public let includingNumbers: Bool

    /// No policy in effect: every option is user-editable.
    public static let unlocked = PasswordPolicyLockedOptions(specialCharacters: false,
                                                             capitalCharacters: false,
                                                             numberCharacters: false,
                                                             capitalizingWords: false,
                                                             includingNumbers: false)

    public init(specialCharacters: Bool,
                capitalCharacters: Bool,
                numberCharacters: Bool,
                capitalizingWords: Bool,
                includingNumbers: Bool) {
        self.specialCharacters = specialCharacters
        self.capitalCharacters = capitalCharacters
        self.numberCharacters = numberCharacters
        self.capitalizingWords = capitalizingWords
        self.includingNumbers = includingNumbers
    }
}
