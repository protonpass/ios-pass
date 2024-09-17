//
// GenerateAuthorizationCredential.swift
// Proton Pass - Created on 26/02/2024.
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
import Client
import Entities
import Foundation
import UseCases

/// Retrieve username/password, resolve passkey challenge or calculate one-time code
protocol GenerateAuthorizationCredentialUseCase: Sendable {
    func execute(_ request: AutoFillRequest) async throws -> (ItemContent, any ASAuthorizationCredential)
}

extension GenerateAuthorizationCredentialUseCase {
    func callAsFunction(_ request: AutoFillRequest) async throws -> (ItemContent, any ASAuthorizationCredential) {
        try await execute(request)
    }
}

final class GenerateAuthorizationCredential: GenerateAuthorizationCredentialUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let resolvePasskeyChallenge: any ResolvePasskeyChallengeUseCase
    private let totpService: any TOTPServiceProtocol

    init(itemRepository: any ItemRepositoryProtocol,
         resolvePasskeyChallenge: any ResolvePasskeyChallengeUseCase,
         totpService: any TOTPServiceProtocol) {
        self.itemRepository = itemRepository
        self.resolvePasskeyChallenge = resolvePasskeyChallenge
        self.totpService = totpService
    }

    func execute(_ request: AutoFillRequest) async throws -> (ItemContent, any ASAuthorizationCredential) {
        guard let recordIdentifier = request.recordIdentifier else {
            throw ASExtensionError(.credentialIdentityNotFound)
        }

        let ids = try IDs.deserializeBase64(recordIdentifier)

        guard let itemContent = try await itemRepository.getItemContent(shareId: ids.shareId,
                                                                        itemId: ids.itemId),
            let logInData = itemContent.loginItem else {
            throw ASExtensionError(.credentialIdentityNotFound)
        }

        let credential: any ASAuthorizationCredential

        switch request {
        case .password:
            credential = ASPasswordCredential(user: logInData.authIdentifier, password: logInData.password)

        case let .passkey(credentialRequest):
            guard let key = logInData.passkeys.key(for: credentialRequest) else {
                throw ASExtensionError(.credentialIdentityNotFound)
            }

            let serviceId = credentialRequest.serviceIdentifier.identifier
            let response = try resolvePasskeyChallenge(serviceIdentifier: serviceId,
                                                       clientDataHash: credentialRequest.clientDataHash,
                                                       passkey: key.content)
            if #available(iOS 17.0, *) {
                credential = ASPasskeyAssertionCredential(userHandle: key.userHandle,
                                                          relyingParty: key.rpID,
                                                          signature: response.signature,
                                                          clientDataHash: response.clientDataHash,
                                                          authenticatorData: response.authenticatorData,
                                                          credentialID: response.credentialId)
            } else {
                assertionFailure("Should be on iOS 17 and above when entering this case")
                credential = ASPasswordCredential(user: logInData.authIdentifier,
                                                  password: logInData.password)
            }

        case .oneTimeCode:
            if #available(iOS 18, *) {
                let token = try totpService.generateTotpToken(uri: logInData.totpUri)
                credential = ASOneTimeCodeCredential(code: token.code)
            } else {
                assertionFailure("Should be on iOS 18 and above when entering this case")
                credential = ASPasswordCredential(user: logInData.authIdentifier,
                                                  password: logInData.password)
            }
        }

        return (itemContent, credential)
    }
}

private extension [Passkey] {
    func key(for request: PasskeyCredentialRequest) -> Passkey? {
        first {
            $0.rpID == request.relyingPartyIdentifier &&
                $0.userName == request.userName
        }
    }
}
