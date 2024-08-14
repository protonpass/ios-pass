//
// CredentialProviderFailureReason.swift
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
    enum CredentialProviderFailureReason: Error, CustomDebugStringConvertible {
        case failedToAuthenticate(String?)
        case invalidURL(URL?)
        case missingRecordIdentifier
        case notLogInItem
        case userCancelled
        case generic

        public var debugDescription: String {
            switch self {
            case .failedToAuthenticate:
                "Failed to authenticate"
            case let .invalidURL(url):
                "Invalid URL \"\(String(describing: url?.absoluteString))\""
            case .missingRecordIdentifier:
                "ASPasswordCredentialIdentity object missing record identifier"
            case .notLogInItem:
                "Not log in item"
            case .userCancelled:
                "User cancelled"
            case .generic:
                "Something went wrong"
            }
        }
    }
}
