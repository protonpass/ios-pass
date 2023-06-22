//
// AliasPrefixValidator.swift
// Proton Pass - Created on 21/11/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public enum AliasPrefixError: LocalizedError {
    case emptyPrefix
    case disallowedCharacters
    case twoConsecutiveDots
    case dotAtTheEnd

    public var localizedDescription: String {
        switch self {
        case .emptyPrefix:
            return "Prefix can not be empty"
        case .disallowedCharacters:
            return "Prefix must contain only lowercase alphanumeric (a-z, 0-9), dot (.), hyphen (-) & underscore (_)."
        case .twoConsecutiveDots:
            return "Prefix can not contain 2 consecutive dots (..)"
        case .dotAtTheEnd:
            return "Alias can not contain 2 consecutive dots (..)"
        }
    }
}

public enum AliasPrefixValidator {
    public static let allowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._-")

    /// Validate a given prefix.
    /// - Parameters:
    ///  - prefix: Prefix to be validated.
    /// - Returns: Nothing if success, throw`AliasPrefixError` if failure.
    public static func validate(prefix: String) throws {
        guard !prefix.isEmpty else {
            throw AliasPrefixError.emptyPrefix
        }

        guard prefix.isValid(allowedCharacters: allowedCharacters) else {
            throw AliasPrefixError.disallowedCharacters
        }

        guard !prefix.contains("..") else {
            throw AliasPrefixError.twoConsecutiveDots
        }

        guard prefix.last != "." else {
            throw AliasPrefixError.dotAtTheEnd
        }
    }
}
