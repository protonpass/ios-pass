//
// CredentialIdentity.swift
// Proton Pass - Created on 28/02/2024.
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

public enum CredentialIdentity {
    case password(PasswordCredentialIdentity)
    case oneTimeCode(OneTimeCodeIdentity)
    case passkey(PasskeyCredentialIdentity)
}

/// A proxy object for `ASPasswordCredentialIdentity` to interact with the credential database
public struct PasswordCredentialIdentity: Sendable {
    /// Maps the `recordIdentifier` property
    public let ids: IDs
    /// Maps the `user` property
    public let username: String
    /// Maps the `serviceIdentifier` property
    public let url: String
    /// Maps the `rank` property
    public let lastUseTime: Int64

    public init(shareId: String,
                itemId: String,
                username: String,
                url: String,
                lastUseTime: Int64) {
        ids = .init(shareId: shareId, itemId: itemId)
        self.username = username
        self.url = url
        self.lastUseTime = lastUseTime
    }
}

public struct OneTimeCodeIdentity: Sendable {
    /// Maps the `recordIdentifier` property
    public let ids: IDs
    /// Maps the `label` property
    public let username: String
    /// Maps the `serviceIdentifier` property
    public let url: String
    /// Maps the `rank` property
    public let lastUseTime: Int64

    public init(shareId: String,
                itemId: String,
                username: String,
                url: String,
                lastUseTime: Int64) {
        ids = .init(shareId: shareId, itemId: itemId)
        self.username = username
        self.url = url
        self.lastUseTime = lastUseTime
    }
}

/// A proxy object for `ASPasskeyCredentialIdentity` to interact with the credential database
public struct PasskeyCredentialIdentity: Sendable {
    /// Maps the `recordIdentifier` property
    public let ids: IDs
    public let relyingPartyIdentifier: String
    public let userName: String
    public let userHandle: Data
    public let credentialId: Data

    public init(shareId: String,
                itemId: String,
                relyingPartyIdentifier: String,
                userName: String,
                userHandle: Data,
                credentialId: Data) {
        ids = .init(shareId: shareId, itemId: itemId)
        self.relyingPartyIdentifier = relyingPartyIdentifier
        self.userName = userName
        self.userHandle = userHandle
        self.credentialId = credentialId
    }
}
