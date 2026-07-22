//
// PasswordPenalty+Extensions.swift
// Proton Pass - Created on 22/07/2026.
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
import Macro

public extension PasswordPenalty {
    var title: String {
        switch self {
        case .noLowercase: #localized("Lowercase letters", bundle: .module)
        case .noUppercase: #localized("Uppercase letters", bundle: .module)
        case .noNumbers: #localized("Numbers", bundle: .module)
        case .noSymbols: #localized("Symbols", bundle: .module)
        case .short: #localized("At least 12 characters", bundle: .module)
        case .consecutive: #localized("No repeated characters", bundle: .module)
        case .progressive: #localized("No sequential characters", bundle: .module)
        case .containsCommonPassword: #localized("No common passwords", bundle: .module)
        }
    }
}
