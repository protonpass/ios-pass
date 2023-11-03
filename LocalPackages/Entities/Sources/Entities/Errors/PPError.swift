//
// PPError.swift
// Proton Pass - Created on 08/02/2023.
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

/// Proton Pass errors
public enum PassError: Error, CustomDebugStringConvertible {
    /// AutoFill extension
    case credentialProvider(CredentialProviderFailureReason)
    case deallocatedSelf
    case failedToGetOrCreateSymmetricKey
    case noUserData
    case itemNotFound(shareID: String, itemID: String)
    case vault(VaultFailureReason)

    public var debugDescription: String {
        switch self {
        case let .credentialProvider(reason):
            reason.debugDescription
        case .deallocatedSelf:
            "Failed to access deallocated self"
        case .failedToGetOrCreateSymmetricKey:
            "Failed to get or create symmetric key"
        case .noUserData:
            "No user data currently accessible"
        case let .itemNotFound(shareID, itemID):
            "Item not found \"\(itemID)\" - Share ID \"\(shareID)\""
        case let .vault(reason):
            reason.debugDescription
        }
    }
}

// MARK: - VaultFailureReason

public extension PassError {
    enum VaultFailureReason: CustomDebugStringConvertible {
        case canNotDeleteLastVault
        case noSelectedVault
        case vaultNotEmpty(String)
        case vaultNotFound(String)

        public var debugDescription: String {
            switch self {
            case .canNotDeleteLastVault:
                "Can not delete last vault"
            case .noSelectedVault:
                "No selected vault"
            case let .vaultNotEmpty(id):
                "Vault not empty \"\(id)\""
            case let .vaultNotFound(id):
                "Vault not found \"\(id)\""
            }
        }
    }
}

// MARK: - CredentialProviderFailureReason

public extension PassError {
    enum CredentialProviderFailureReason: Error, CustomDebugStringConvertible {
        case failedToAuthenticate
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
