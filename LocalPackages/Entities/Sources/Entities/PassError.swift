//
// PassError.swift
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

import CoreData
import Foundation

/// Proton Pass errors
public enum PassError: Error, CustomDebugStringConvertible {
    /// AutoFill extension
    case credentialProvider(CredentialProviderFailureReason)
    case deallocatedSelf
    case failedToGetOrCreateSymmetricKey
    case noUserData
    case vault(VaultFailureReason)
    case coreData(CoreDataFailureReason)
    case corruptedEncryptedContent
    case corruptedUserData(UserDataCorruptionReason)
    case crypto(CryptoFailureReason)
    case errorExpected
    case itemNotFound(ItemIdentifiable)
    case keysNotFound(shareID: String)
    case shareNotFoundInLocalDB(shareID: String)
    case symmetricEncryption(SymmetricEncryptionFailureReason)
    case unexpectedError
    case unexpectedHttpStatusCode(Int?)
    case unexpectedLogout
    case unknownShareType
    case unmatchedRotationID(leftID: String, rightID: String)
    case sharing(SharingErrorReason)

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
        case let .vault(reason):
            reason.debugDescription
        case let .coreData(reason):
            reason.debugDescription
        case .corruptedEncryptedContent:
            "Corrupted encrypted content"
        case let .corruptedUserData(reason):
            reason.debugDescription
        case let .crypto(reason):
            reason.debugDescription
        case .errorExpected:
            "An error is expected"
        case let .itemNotFound(item):
            "Item not found ID \"\(item.itemId)\", share ID \"\(item.shareId)\""
        case let .keysNotFound(shareID):
            "Keys not found for share \"\(shareID)\""
        case let .shareNotFoundInLocalDB(shareID):
            "Share not found in local DB \"\(shareID)\""
        case let .symmetricEncryption(reason):
            reason.debugDescription
        case .unexpectedError:
            "Unexpected error"
        case let .unexpectedHttpStatusCode(statusCode):
            "Unexpected HTTP status code \(String(describing: statusCode))"
        case .unknownShareType:
            "Unknown share type"
        case .unexpectedLogout:
            "Unexpected logout"
        case let .unmatchedRotationID(leftID, rightID):
            "Unmatched rotation IDs \"\(leftID)\" & \"\(rightID)\""
        case let .sharing(reason):
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

// MARK: - CoreDataFailureReason

public extension PassError {
    enum CoreDataFailureReason: CustomDebugStringConvertible, @unchecked Sendable {
        case corrupted(object: NSManagedObject, property: String)
        case corruptedShareKeys(shareId: String)

        public var debugDescription: String {
            switch self {
            case let .corrupted(object, property):
                "Corrupted \(type(of: object)): missing value for \(property)"
            case let .corruptedShareKeys(shareId):
                "ItemKeys & VaultKeys are not synced for share with ID \(shareId)"
            }
        }
    }
}

// MARK: - UserDataCorruptionReason

public extension PassError {
    enum UserDataCorruptionReason: CustomDebugStringConvertible, Sendable {
        case noAddresses
        case noAddressKeys
        case failedToGetAddressKeyPassphrase

        public var debugDescription: String {
            switch self {
            case .noAddresses:
                "No addresses"
            case .noAddressKeys:
                "No address keys"
            case .failedToGetAddressKeyPassphrase:
                "Failed to get address key passphrase"
            }
        }
    }
}

// MARK: - CryptoFailureReason

public extension PassError {
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
                "Failed to split PGP message"
            case let .failedToUnarmor(string):
                "Failed to unarmor \(string)"
            case let .failedToArmor(string):
                "Failed to armor \(string)"
            case .failedToBase64Decode:
                "Failed to base 64 decode"
            case .failedToBase64Encode:
                "Failed to base 64 encode"
            case .failedToGetFingerprint:
                "Failed to get fingerprint"
            case .failedToGenerateKeyRing:
                "Failed to generate key ring"
            case .failedToEncrypt:
                "Failed to encrypt"
            case .failedToVerifyVault:
                "Failed to verify vault"
            case .failedToDecryptContent:
                "Failed to decrypt content"
            case .failedToVerifySignature:
                "Failed to verify signature"
            case .failedToGenerateSessionKey:
                "Failed to generate session key"
            case .failedToDecode:
                "Failed to decode"
            case let .failedToEncode(string):
                "Failed to encode \"\(string)\""
            case .failedToAESEncrypt:
                "Failed to AES encrypt"
            case let .inactiveUserKey(userKeyId):
                "Inactive user key \(userKeyId)"
            case let .addressNotFound(addressID):
                "Address not found \"\(addressID)\""
            case let .corruptedShareContent(shareID):
                "Corrupted share content shareID \"\(shareID)\""
            case let .missingUserKey(userID):
                "Missing user key \"\(userID)\""
            case let .missingPassphrase(keyID):
                "Missing passphrase \"\(keyID)\""
            case .missingKeys:
                "Missing keys"
            case let .unmatchedKeyRotation(lhsKey, rhsKey):
                "Unmatch key rotation \(lhsKey) - \(rhsKey)"
            }
        }
    }
}

// MARK: - SymmetricEncryptionFailureReason

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

// MARK: - SharingErrorReason

public extension PassError {
    enum SharingErrorReason: CustomDebugStringConvertible, LocalizedError, Equatable {
        case incompleteInformation
        case failedEncryptionKeysFetching
        case noPublicKeyAssociatedWithEmail(String)
        case invalidKeyOrAddress
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
            case .invalidKeyOrAddress:
                "Invalid key or address"
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
