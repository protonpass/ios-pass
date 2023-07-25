//
// CryptoKeyError+Extensions.swift
// Proton Pass - Created on 25/07/2023.
// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCore_Crypto

extension CryptoKeyError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noKeyCouldBeUnlocked:
            return "Keys could not be unlocked"
        case .noKeyCouldBeParsed:
            return "Keys could not be parsed"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case let .noKeyCouldBeUnlocked(errors):
            return "Keys unlocking failed due to \(errors)"
        case let .noKeyCouldBeParsed(errors):
            return "Keys parsing failed due to \(errors)"
        }
    }
}
