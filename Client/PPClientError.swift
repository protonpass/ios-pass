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
    case shareNotFoundInLocalDB(shareID: String)
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
        case .shareNotFoundInLocalDB(let shareID):
            return "Share not found in local DB \"\(shareID)\""
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
