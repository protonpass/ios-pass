//
// CreatePasskeyResponse.swift
// Proton Pass - Created on 05/03/2024.
// Copyright (c) 2024 Proton Technologies AG
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

public struct CreatePasskeyResponse: Hashable, Sendable {
    public let passkey: Data
    public let keyId: String
    public let domain: String
    public let rpId: String?
    public let rpName: String
    public let userName: String
    public let userDisplayName: String
    public let userId: Data
    public let credentialId: Data
    public let clientDataHash: Data
    public let userHandle: Data?
    public let attestationObject: Data

    public init(passkey: Data,
                keyId: String,
                domain: String,
                rpId: String?,
                rpName: String,
                userName: String,
                userDisplayName: String,
                userId: Data,
                credentialId: Data,
                clientDataHash: Data,
                userHandle: Data?,
                attestationObject: Data) {
        self.passkey = passkey
        self.keyId = keyId
        self.domain = domain
        self.rpId = rpId
        self.rpName = rpName
        self.userName = userName
        self.userDisplayName = userDisplayName
        self.userId = userId
        self.credentialId = credentialId
        self.clientDataHash = clientDataHash
        self.userHandle = userHandle
        self.attestationObject = attestationObject
    }
}

public extension CreatePasskeyResponse {
    var toPasskey: Passkey {
        var passkey = Passkey()
        passkey.keyID = keyId
        passkey.content = self.passkey
        passkey.domain = domain
        passkey.rpID = rpId ?? ""
        passkey.rpName = rpName
        passkey.userName = userName
        passkey.userDisplayName = userDisplayName
        passkey.userID = userId
        passkey.createTime = UInt32(Date.now.timeIntervalSince1970)
        passkey.credentialID = credentialId
        passkey.userHandle = userHandle ?? .init()
        return passkey
    }
}
