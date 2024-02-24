//
// ResolvePasskeyChallenge.swift
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

import AuthenticationServices
import Entities
import Foundation
import PassRustCore

@available(iOS 17.0, *)
public protocol ResolvePasskeyChallengeUseCase: Sendable {
    func execute(request: any ASCredentialRequest, passkey: Data) throws -> AuthenticateWithPasskeyIosResponse
}

@available(iOS 17.0, *)
public extension ResolvePasskeyChallengeUseCase {
    func callAsFunction(request: any ASCredentialRequest,
                        passkey: Data) throws -> AuthenticateWithPasskeyIosResponse {
        try execute(request: request, passkey: passkey)
    }
}

@available(iOS 17.0, *)
public final class ResolvePasskeyChallenge: ResolvePasskeyChallengeUseCase {
    public init() {}

    public func execute(request: any ASCredentialRequest,
                        passkey: Data) throws -> AuthenticateWithPasskeyIosResponse {
        guard let request = request as? ASPasskeyCredentialRequest else {
            throw PassError.passkey(.failedToParseCredentialRequest)
        }

        let serviceIdentifier = request.credentialIdentity.serviceIdentifier.identifier
        let resolveRequest = AuthenticateWithPasskeyIosRequest(serviceIdentifier: serviceIdentifier,
                                                               passkey: passkey,
                                                               clientDataHash: request.clientDataHash)
        return try PasskeyManager().resolveChallengeForIos(request: resolveRequest)
    }
}
