//
// CompromisedPasswordsFailureReason.swift
// Proton Pass - Created on 01/07/2026.
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

public extension PassError {
    enum CompromisedPasswordsFailureReason: Error, Equatable, CustomDebugStringConvertible {
        case invalidURL(String)
        case invalidResponse
        case invalidPrefixSize(Int)
        case unexpectedStatusCode(Int)
        case invalidLastChangePayload

        public var debugDescription: String {
            switch self {
            case let .invalidURL(url):
                "Invalid URL: \(url)"

            case .invalidResponse:
                "Invalid network response"

            case let .unexpectedStatusCode(code):
                "Unexpected statuc code \(code)"

            case .invalidLastChangePayload:
                "Invalid last change payload"

            case let .invalidPrefixSize(size):
                "Invalid prefix size \(size)"
            }
        }
    }
}
