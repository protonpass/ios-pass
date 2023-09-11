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
public enum PPClientError: Error, CustomDebugStringConvertible, LocalizedError {
    case coreData(CoreDataFailureReason)
    case corruptedEncryptedContent
    case corruptedUserData(UserDataCorruptionReason)
    case crypto(CryptoFailureReason)
    case errorExpected
    case itemNotFound(item: ItemIdentifiable)
    case keysNotFound(shareID: String)
    case shareNotFoundInLocalDB(shareID: String)
    case symmetricEncryption(SymmetricEncryptionFailureReason)
    case unexpectedError
    case unexpectedHttpStatusCode(Int?)
    case unknownShareType
    case unmatchedRotationID(leftID: String, rightID: String)

    public var debugDescription: String {
        switch self {
        case let .coreData(reason):
            return reason.debugDescription
        case .corruptedEncryptedContent:
            return "Corrupted encrypted content"
        case let .corruptedUserData(reason):
            return reason.debugDescription
        case let .crypto(reason):
            return reason.debugDescription
        case .errorExpected:
            return "An error is expected"
        case let .itemNotFound(item):
            return "Item not found ID \"\(item.itemId)\", share ID \"\(item.shareId)\""
        case let .keysNotFound(shareID):
            return "Keys not found for share \"\(shareID)\""
        case let .shareNotFoundInLocalDB(shareID):
            return "Share not found in local DB \"\(shareID)\""
        case let .symmetricEncryption(reason):
            return reason.debugDescription
        case .unexpectedError:
            return "Unexpected error"
        case let .unexpectedHttpStatusCode(statusCode):
            return "Unexpected HTTP status code \(String(describing: statusCode))"
        case .unknownShareType:
            return "Unknown share type"
        case let .unmatchedRotationID(leftID, rightID):
            return "Unmatched rotation IDs \"\(leftID)\" & \"\(rightID)\""
        }
    }
}

// MARK: - CoreDataFailureReason

public extension PPClientError {
    enum CoreDataFailureReason: CustomDebugStringConvertible, Sendable {
        case corrupted(object: NSManagedObject, property: String)
        case corruptedShareKeys(shareId: String)

        public var debugDescription: String {
            switch self {
            case let .corrupted(object, property):
                return "Corrupted \(type(of: object)): missing value for \(property)"
            case let .corruptedShareKeys(shareId):
                return "ItemKeys & VaultKeys are not synced for share with ID \(shareId)"
            }
        }
    }
}

// MARK: - UserDataCorruptionReason

public extension PPClientError {
    enum UserDataCorruptionReason: CustomDebugStringConvertible, Sendable {
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

// MARK: - CryptoFailureReason

public extension PPClientError {
    enum CryptoFailureReason: CustomDebugStringConvertible, Sendable {
        case failedToSplitPGPMessage
        case failedToUnarmor(String)
        case failedToArmor(String)
        case failedToBase64Decode
        case failedToBase64Encode
        case failedToGetFingerprint
        case failedToGenerateKeyRing
        case failedToEncrypt
        case failedToVerifyVault
        case failedToDecryptContent
        case failedToVerifySignature
        case failedToGenerateSessionKey
        case failedToDecode
        case failedToEncode(String)
        case failedToAESEncrypt
        case inactiveUserKey(userKeyId: String) // Caused by "forgot password"
        case addressNotFound(addressID: String)
        case corruptedShareContent(shareID: String)
        case missingUserKey(userID: String)
        case missingPassphrase(keyID: String)
        case missingKeys
        case unmatchedKeyRotation(lhsKey: Int64, rhsKey: Int64)

        public var debugDescription: String {
            switch self {
            case .failedToSplitPGPMessage:
                return "Failed to split PGP message"
            case let .failedToUnarmor(string):
                return "Failed to unarmor \(string)"
            case let .failedToArmor(string):
                return "Failed to armor \(string)"
            case .failedToBase64Decode:
                return "Failed to base 64 decode"
            case .failedToBase64Encode:
                return "Failed to base 64 encode"
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
            case let .failedToEncode(string):
                return "Failed to encode \"\(string)\""
            case .failedToAESEncrypt:
                return "Failed to AES encrypt"
            case let .inactiveUserKey(userKeyId):
                return "Inactive user key \(userKeyId)"
            case let .addressNotFound(addressID):
                return "Address not found \"\(addressID)\""
            case let .corruptedShareContent(shareID):
                return "Corrupted share content shareID \"\(shareID)\""
            case let .missingUserKey(userID):
                return "Missing user key \"\(userID)\""
            case let .missingPassphrase(keyID):
                return "Missing passphrase \"\(keyID)\""
            case .missingKeys:
                return "Missing keys"
            case let .unmatchedKeyRotation(lhsKey, rhsKey):
                return "Unmatch key rotation \(lhsKey) - \(rhsKey)"
            }
        }
    }
}

public extension PPClientError {
    enum SymmetricEncryptionFailureReason: CustomDebugStringConvertible, Sendable {
        case failedToUtf8ConvertToData(String)
        case failedToBase64Decode(String)
        case failedToUtf8Decode

        public var debugDescription: String {
            switch self {
            case let .failedToUtf8ConvertToData(string):
                return "Failed to UTF8 convert to data \"\(string)\""
            case let .failedToBase64Decode(string):
                return "Failed to base 64 decode \"\(string)\""
            case .failedToUtf8Decode:
                return "Failed to UTF8 decode"
            }
        }
    }
}
