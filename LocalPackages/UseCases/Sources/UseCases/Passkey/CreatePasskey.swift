//
// CreatePasskey.swift
// Proton Pass - Created on 20/02/2024.
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

import AuthenticationServices
import Entities
import Foundation
import PassRustCore

@available(iOS 17, *)
public protocol CreatePasskeyUseCase: Sendable {
    func execute(_ request: any ASCredentialRequest) throws -> CreatePasskeyIosResponse
}

@available(iOS 17, *)
public extension CreatePasskeyUseCase {
    func callAsFunction(_ request: any ASCredentialRequest) throws -> CreatePasskeyIosResponse {
        try execute(request)
    }
}

@available(iOS 17, *)
public final class CreatePasskey: CreatePasskeyUseCase {
    public init() {}

    public func execute(_ request: any ASCredentialRequest) throws -> CreatePasskeyIosResponse {
        guard let request = request as? ASPasskeyCredentialRequest,
              let credentialIdentity = request.credentialIdentity as? ASPasskeyCredentialIdentity else {
            throw PassError.passkey(.failedToParseCredentialRequest)
        }
        let createRequest = CreatePasskeyIosRequest(serviceIdentifier: credentialIdentity.serviceIdentifier
            .identifier,
            rpId: credentialIdentity.relyingPartyIdentifier,
            userName: credentialIdentity.userName,
            userHandle: credentialIdentity.userHandle)
        let manager = try PasskeyManager()
        return try manager.generateIosPasskey(request: createRequest)
    }
}
