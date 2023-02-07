//
// PPClientError.swift
// Proton Pass - Created on 07/02/2023.
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

import CoreData
import Foundation

/// Proton Pass client module related errors.
public enum PPClientError: Error, CustomDebugStringConvertible {
    case coreData(CoreDataFailureReason)
    case corruptedEncryptedContent
    case corruptedUserData(UserDataCorruptionReason)
    case crypto(CryptoFailureReason)
    case keys(KeysFailureReason)
    case networkOperationsOnMainThread
    case shareNotFoundInLocalDB(shareID: String)
    case symmetricEncryption(SymmetricEncryptionFailureReason)
    case unknownShareType
    case unmatchedRotationID(leftID: String, rightID: String)

    public var debugDescription: String {
        switch self {
        case .coreData(let reason):
            return reason.debugDescription
        case .corruptedEncryptedContent:
            return "Corrupted encrypted content"
        case .corruptedUserData(let reason):
            return reason.debugDescription
        case .crypto(let reason):
            return reason.debugDescription
        case .keys(let reason):
            return reason.debugDescription
        case .networkOperationsOnMainThread:
            return "Network operations shouldn't be called on main thread"
        case .shareNotFoundInLocalDB(let shareID):
            return "Share not found in local DB \"\(shareID)\""
        case .symmetricEncryption(let reason):
            return reason.debugDescription
        case .unknownShareType:
            return "Unknown share type"
        case let .unmatchedRotationID(leftID, rightID):
            return "Unmatched rotation IDs \"\(leftID)\" & \"\(rightID)\""
        }
    }
}

// MARK: - CoreDataFailureReason
public extension PPClientError {
    enum CoreDataFailureReason: CustomDebugStringConvertible {
        case corrupted(object: NSManagedObject, property: String)
        case corruptedShareKeys(shareId: String)

        public var debugDescription: String {
            switch self {
            case let .corrupted(object, property):
                return "Corrupted \(type(of: object)): missing value for \(property)"
            case .corruptedShareKeys(let shareId):
                return "ItemKeys & VaultKeys are not synced for share with ID \(shareId)"
            }
        }
    }
}

// MARK: - UserDataCorruptionReason
public extension PPClientError {
    enum UserDataCorruptionReason: CustomDebugStringConvertible {
        case noAddresses
        case noAddressKeys
        case failedToGetAddressKeyPassphrase

        public var debugDescription: String {
            switch self {
            case .noAddresses:
                return "No addresses"
            case .noAddressKeys:
                return "No address keys"
            case .failedToGetAddressKeyPassphrase:
                return "Failed to get address key passphrase"
            }
        }
    }
}

// MARK: - KeysFailureReason
public extension PPClientError {
    enum KeysFailureReason: CustomDebugStringConvertible {
        case vaultKeyNotFound(shareID: String)
        case itemKeyNotFound(shareID: String, rotationID: String)

        public var debugDescription: String {
            switch self {
            case .vaultKeyNotFound(let shareID):
                return "Vault key not found for share \"\(shareID)\""
            case let .itemKeyNotFound(shareID, rotationID):
                return "Item key not found for share \"\(shareID)\" rotation ID \"\(rotationID)\""
            }
        }
    }
}

// MARK: - CryptoFailureReason
public extension PPClientError {
    enum CryptoFailureReason: CustomDebugStringConvertible {
        case failedToSplitPGPMessage
        case failedToUnarmor(String)
        case failedToArmor(String)
        case failedToGetFingerprint
        case failedToGenerateKeyRing
        case failedToEncrypt
        case failedToVerifyVault
        case failedToDecryptContent
        case failedToVerifySignature
        case failedToGenerateSessionKey
        case failedToDecode
        case addressNotFound(addressID: String)

        public var debugDescription: String {
            switch self {
            case .failedToSplitPGPMessage:
                return "Failed to split PGP message"
            case .failedToUnarmor(let string):
                return "Failed to unarmor \(string)"
            case .failedToArmor(let string):
                return "Failed to armor \(string)"
            case .failedToGetFingerprint:
                return "Failed to get fingerprint"
            case .failedToGenerateKeyRing:
                return "Failed to generate key ring"
            case .failedToEncrypt:
                return "Failed to encrypt"
            case .failedToVerifyVault:
                return "Failed to verify vault"
            case .failedToDecryptContent:
                return "Failed to decrypt content"
            case .failedToVerifySignature:
                return "Failed to verify signature"
            case .failedToGenerateSessionKey:
                return "Failed to generate session key"
            case .failedToDecode:
                return "Failed to decode"
            case .addressNotFound(let addressID):
                return "Address not found \"\(addressID)\""
            }
        }
    }
}

public extension PPClientError {
    enum SymmetricEncryptionFailureReason: CustomDebugStringConvertible {
        case failedToUtf8ConvertToData(String)
        case failedToBase64Decode(String)
        case failedToUtf8Decode

        public var debugDescription: String {
            switch self {
            case .failedToUtf8ConvertToData(let string):
                return "Failed to UTF8 convert to data \"\(string)\""
            case .failedToBase64Decode(let string):
                return "Failed to base 64 decode \"\(string)\""
            case .failedToUtf8Decode:
                return "Failed to UTF8 decode"
            }
        }
    }
}
