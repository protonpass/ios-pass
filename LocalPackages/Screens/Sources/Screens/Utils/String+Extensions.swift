//
// String+Extensions.swift
// Proton Pass - Created on 10/04/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Core
import DesignSystem
import SwiftUI

public extension String {
    func coloredPassword() -> AttributedString {
        let attributedChars = map { char in
            var attributedChar = AttributedString("\(char)", attributes: .lineBreakHyphenErasing)
            attributedChar.foregroundColor = if AllowedCharacter.digit.rawValue.contains(char) {
                PassColor.loginInteractionNormMajor2
            } else if AllowedCharacter.special.rawValue.contains(char) ||
                AllowedCharacter.separator.rawValue.contains(char) {
                PassColor.aliasInteractionNormMajor2
            } else {
                PassColor.textNorm
            }
            return attributedChar
        }
        return attributedChars.reduce(into: .init()) { $0 += $1 }
    }
}
