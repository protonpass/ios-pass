//
// OrganizationKey.swift
// Proton Pass - Created on 29/09/2025.
// Copyright (c) 2025 Proton Technologies AG
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

/// 0 - is not supposed to have access to org key, 1 - has access to org key, 2 - has lost access to key and needs
/// to be re-invited, 3 - pending activation
public enum AccessToOrgKeyPermission: Int, Decodable, Sendable {
    case noAccess = 0
    case hasAccess = 1
    case hasLostAccessNeedToRequestAgain = 2
    case pendingActivation = 3
}

public struct OrganizationKey: Sendable, Decodable, Equatable {
    /// Organization private key encrypted with mailbox password hash
    public let privateKey: String?
    /// If migrating to passwordless key, the private org key encrypted to the user mailbox pass
    public let legacyPrivateKey: String?
    /// Organization public key **Deprecated**
    public let publicKey: String?
    /// Token (key + data packets) to access the passwordless organization key for this user
    public let token: String?
    /// Signature of the token secret
    public let signature: String?
    /// Address email of the admin that signed the token (if not the user key of the member themself)
    public let signatureAddress: String?
    /// The address ID of the address that was invited to the organization key
    public let encryptionAddressID: String?
    /// Signature of the SHA256 fingerprint of the organization key
    public let fingerprintSignature: String?
    // The email address that signed the SHA256 fingerprint of the organization key
    public let fingerprintSignatureAddress: String?
    public let accessToOrgKey: AccessToOrgKeyPermission?
    /// Whether the organization has passwordless keys or not
    public let passwordless: Bool

    public var isPasswordless: Bool {
        if passwordless {
            return true
        }
        return signature != nil && token != nil && privateKey != nil
    }
}
