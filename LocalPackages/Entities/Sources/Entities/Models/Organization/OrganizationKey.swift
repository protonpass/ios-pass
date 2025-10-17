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

public enum AccessToOrgKeyPermission: Int, Decodable, Sendable {
    case noAccess = 0
    case hasAccess = 1
    case hasLostAccessNeedToRequestAgain = 2
    case pendingActivation = 3
}

public struct OrganizationKey: Sendable, Decodable, Equatable {
    public let privateKey: String?
    public let legacyPrivateKey: String?
    public let publicKey: String?
    public var token: String?
    public var signature: String?
    public var signatureAddress: String?
    public var encryptionAddressID: String?
    public var fingerprintSignature: String?
    public var fingerprintSignatureAddress: String?
    public var accessToOrgKey: AccessToOrgKeyPermission?
    public var passwordless: Bool

    public var isPasswordless: Bool {
        if passwordless {
            return true
        }
        guard signature != nil, token != nil, privateKey != nil else { return false }
        return true
    }
}
