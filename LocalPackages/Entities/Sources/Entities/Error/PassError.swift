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

import Foundation

/// Proton Pass errors
public enum PassError: Error, CustomDebugStringConvertible, Equatable {
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
    case itemNotFound(any ItemIdentifiable)
    case keysNotFound(shareID: String)
    case shareNotFoundInLocalDB(shareID: String)
    case symmetricEncryption(SymmetricEncryptionFailureReason)
    case unexpectedError
    case unexpectedLogout
    case unknownShareType
    case unmatchedRotationID(leftID: String, rightID: String)
    case sharing(SharingFailureReason)
    case network(NetworkFailureReason)
    case invalidUrl(String)
    case userDefault(UserDefaultFailureReason)
    case biometricChange
    case failedToConvertBase64StringToData(String)
    case organizationNotFound
    case preferences(PreferencesFailureReason)
    case mainKeyNotFound
    case sentinelNotEligible
    case userManager(UserManagerFailureReason)
    case extraPassword(ExtraPasswordFailureReason)
    case payments(PaymentFailureReason)
    case api(APIFailureReason)
    case fileAttachment(FileAttachmentReason)
    case csv(CsvFailureReason)

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
        case .unknownShareType:
            "Unknown share type"
        case .unexpectedLogout:
            "Unexpected logout"
        case let .unmatchedRotationID(leftID, rightID):
            "Unmatched rotation IDs \"\(leftID)\" & \"\(rightID)\""
        case let .sharing(reason):
            reason.debugDescription
        case let .network(reason):
            reason.debugDescription
        case let .invalidUrl(url):
            "Invalid URL \(url)"
        case let .userDefault(reason):
            reason.debugDescription
        case .biometricChange:
            "We detected a change in recorded biometric"
        case let .failedToConvertBase64StringToData(string):
            "Failed to convert base 64 string to data \"\(string)\""
        case .organizationNotFound:
            "Organization not found"
        case let .preferences(reason):
            reason.debugDescription
        case .mainKeyNotFound:
            "Main key not found"
        case .sentinelNotEligible:
            "Sentinel not eligible"
        case let .userManager(reason):
            reason.debugDescription
        case let .extraPassword(reason):
            reason.debugDescription
        case let .payments(reason):
            reason.debugDescription
        case let .api(reason):
            reason.debugDescription
        case let .fileAttachment(reason):
            reason.debugDescription
        case let .csv(reason):
            reason.debugDescription
        }
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.debugDescription == rhs.debugDescription
    }
}
