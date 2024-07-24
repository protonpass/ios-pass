//
// AutoFillPasskey.swift
// Proton Pass - Created on 29/02/2024.
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

import AuthenticationServices
import Entities
import Foundation
import UseCases

protocol AutoFillPasskeyUseCase: Sendable {
    func execute(_ passkey: Passkey,
                 itemContent: ItemContent,
                 userId: String,
                 identifiers: [ASCredentialServiceIdentifier],
                 params: any PasskeyRequestParametersProtocol,
                 context: ASCredentialProviderExtensionContext) async throws
}

extension AutoFillPasskeyUseCase {
    func callAsFunction(_ passkey: Passkey,
                        itemContent: ItemContent,
                        userId: String,
                        identifiers: [ASCredentialServiceIdentifier],
                        params: any PasskeyRequestParametersProtocol,
                        context: ASCredentialProviderExtensionContext) async throws {
        try await execute(passkey,
                          itemContent: itemContent,
                          userId: userId,
                          identifiers: identifiers,
                          params: params,
                          context: context)
    }
}

final class AutoFillPasskey: AutoFillPasskeyUseCase {
    private let resolveChallenge: any ResolvePasskeyChallengeUseCase
    private let completeAutoFill: any CompleteAutoFillUseCase

    init(resolveChallenge: any ResolvePasskeyChallengeUseCase,
         completeAutoFill: any CompleteAutoFillUseCase) {
        self.resolveChallenge = resolveChallenge
        self.completeAutoFill = completeAutoFill
    }

    func execute(_ passkey: Passkey,
                 itemContent: ItemContent,
                 userId: String,
                 identifiers: [ASCredentialServiceIdentifier],
                 params: any PasskeyRequestParametersProtocol,
                 context: ASCredentialProviderExtensionContext) async throws {
        guard #available(iOS 17, *) else {
            assertionFailure("Should be called on iOS 17 and above")
            return
        }

        let response = try resolveChallenge(serviceIdentifier: params.relyingPartyIdentifier,
                                            clientDataHash: params.clientDataHash,
                                            passkey: passkey.content)
        let credential = ASPasskeyAssertionCredential(userHandle: response.userHandle,
                                                      relyingParty: response.relyingParty,
                                                      signature: response.signature,
                                                      clientDataHash: response.clientDataHash,
                                                      authenticatorData: response.authenticatorData,
                                                      credentialID: response.credentialId)
        try await completeAutoFill(quickTypeBar: false,
                                   identifiers: identifiers,
                                   credential: credential,
                                   userId: userId,
                                   itemContent: itemContent,
                                   context: context)
    }
}
