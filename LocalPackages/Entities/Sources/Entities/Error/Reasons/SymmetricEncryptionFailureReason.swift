//
// SymmetricEncryptionFailureReason.swift
// Proton Pass - Created on 10/11/2023.
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
//

import Foundation

public extension PassError {
    enum SymmetricEncryptionFailureReason: CustomDebugStringConvertible, Sendable {
        case failedToUtf8ConvertToData(String)
        case failedToBase64Decode(String)
        case failedToUtf8Decode

        public var debugDescription: String {
            switch self {
            case let .failedToUtf8ConvertToData(string):
                "Failed to UTF8 convert to data \"\(string)\""
            case let .failedToBase64Decode(string):
                "Failed to base 64 decode \"\(string)\""
            case .failedToUtf8Decode:
                "Failed to UTF8 decode"
            }
        }
    }
}
