//
// AliasPrefixError+Extensions.swift
// Proton Pass - Created on 02/01/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import Foundation
import Macro

extension AliasPrefixError: @retroactive LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .emptyPrefix:
            #localized("Prefix can not be empty")
        case .disallowedCharacters:
            // swiftlint:disable:next line_length
            #localized("Prefix must contain only lowercase alphanumeric (a-z, 0-9), dot (.), hyphen (-) & underscore (_)")
        case .twoConsecutiveDots:
            #localized("Prefix can not contain 2 consecutive dots (..)")
        case .dotAtTheEnd:
            #localized("Alias can not contain 2 consecutive dots (..)")
        case .dotAtTheStart:
            #localized("Alias can not start with a dot (.)")
        case .prefixToLong:
            #localized("The alias prefix is too long")
        case .unknown:
            #localized("Invalid prefix")
        }
    }
}
