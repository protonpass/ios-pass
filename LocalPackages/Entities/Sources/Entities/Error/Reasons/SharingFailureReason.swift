//
// SharingFailureReason.swift
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
    enum SharingFailureReason: CustomDebugStringConvertible, LocalizedError, Equatable {
        case incompleteInformation
        case failedEncryptionKeysFetching
        case noPublicKeyAssociatedWithEmail(String)
        case invalidKey
        case invalidAddress(String)
        case cannotDecode
        case failedToCreateNewVault
        case failedToInvite
        case notProtonAddress

        public var debugDescription: String {
            switch self {
            case .incompleteInformation:
                "Incomplete information"
            case .failedEncryptionKeysFetching:
                "Failed to fetch encryption keys"
            case let .noPublicKeyAssociatedWithEmail(email):
                "No public key for email \(email)"
            case .invalidKey:
                "Invalid key"
            case let .invalidAddress(email):
                "Invalid address for email \(email)"
            case .cannotDecode:
                "Cannot decode"
            case .failedToCreateNewVault:
                "Failed to create new vault"
            case .failedToInvite:
                "Failed to invite"
            case .notProtonAddress:
                "Not Proton address"
            }
        }
    }
}
