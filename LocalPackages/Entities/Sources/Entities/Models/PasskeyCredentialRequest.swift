//
// PasskeyCredentialRequest.swift
// Proton Pass - Created on 24/02/2024.
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

@preconcurrency import AuthenticationServices

/// Wrap `ASPasskeyCredentialRequest` as it's iOS 17 only
/// Can be removed once iOS 16 is dropped
public struct PasskeyCredentialRequest: Sendable, Equatable, Hashable {
    public let userName: String
    public let relyingPartyIdentifier: String
    public let serviceIdentifier: ASCredentialServiceIdentifier
    public let recordIdentifier: String?
    public let clientDataHash: Data
    public let userHandle: Data
    public let supportedAlgorithms: [ASCOSEAlgorithmIdentifier]

    public init(userName: String,
                relyingPartyIdentifier: String,
                serviceIdentifier: ASCredentialServiceIdentifier,
                recordIdentifier: String?,
                clientDataHash: Data,
                userHandle: Data,
                supportedAlgorithms: [ASCOSEAlgorithmIdentifier]) {
        self.userName = userName
        self.relyingPartyIdentifier = relyingPartyIdentifier
        self.serviceIdentifier = serviceIdentifier
        self.recordIdentifier = recordIdentifier
        self.clientDataHash = clientDataHash
        self.userHandle = userHandle
        self.supportedAlgorithms = supportedAlgorithms
    }
}
