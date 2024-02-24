//
// CheckAndAutoFill.swift
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

import AuthenticationServices
import Client
import Entities
import Foundation
import UseCases

protocol CheckAndAutoFillUseCase: Sendable {
    func execute(_ credentialIdentity: ASPasswordCredentialIdentity) async throws
    func execute(_ request: PasskeyCredentialRequest) async throws
}

extension CheckAndAutoFillUseCase {
    func callAsFunction(_ credentialIdentity: ASPasswordCredentialIdentity) async throws {
        try await execute(credentialIdentity)
    }

    func callAsFunction(_ request: PasskeyCredentialRequest) async throws {
        try await execute(request)
    }
}

final class CheckAndAutoFill: CheckAndAutoFillUseCase {
    private let itemRepository: any ItemRepositoryProtocol
    private let resolvePasskeyChallenge: any ResolvePasskeyChallengeUseCase
    private let cancelAutoFill: any CancelAutoFillUseCase
    private let completeAutoFill: any CompleteAutoFillUseCase
    private let preferences: Preferences

    init(itemRepository: any ItemRepositoryProtocol,
         resolvePasskeyChallenge: any ResolvePasskeyChallengeUseCase,
         cancelAutoFill: any CancelAutoFillUseCase,
         completeAutoFill: any CompleteAutoFillUseCase,
         preferences: Preferences) {
        self.itemRepository = itemRepository
        self.resolvePasskeyChallenge = resolvePasskeyChallenge
        self.cancelAutoFill = cancelAutoFill
        self.completeAutoFill = completeAutoFill
        self.preferences = preferences
    }

    func execute(_ credentialIdentity: ASPasswordCredentialIdentity) async throws {
        let (itemContent,
             logInData) = try await getLogInData(recordIdentifier: credentialIdentity.recordIdentifier)
        let credential = ASPasswordCredential(user: logInData.username,
                                              password: logInData.password)
        try await completeAutoFill(quickTypeBar: true,
                                   identifiers: [credentialIdentity.serviceIdentifier],
                                   credential: credential,
                                   itemContent: itemContent)
    }

    func execute(_ request: PasskeyCredentialRequest) async throws {
        let (itemContent,
             logInData) = try await getLogInData(recordIdentifier: request.recordIdentifier)

        guard let passkey = logInData.passkeys.first(where: { $0.rpID == request.relyingPartyIdentifier }) else {
            let error = ASExtensionError(.credentialIdentityNotFound)
            cancelAutoFill(reason: error.code)
            throw error
        }

        let response = try resolvePasskeyChallenge(request: request, passkey: passkey.content)
        let credential = ASPasswordCredential(user: logInData.username,
                                              password: logInData.password)
        try await completeAutoFill(quickTypeBar: true,
                                   identifiers: [request.serviceIdentifier],
                                   credential: credential,
                                   itemContent: itemContent)
    }
}

private extension CheckAndAutoFill {
    func getLogInData(recordIdentifier: String?) async throws -> (ItemContent, LogInItemData) {
        guard let recordIdentifier else {
            let error = ASExtensionError(.credentialIdentityNotFound)
            cancelAutoFill(reason: error.code)
            throw error
        }

        guard preferences.localAuthenticationMethod == .none else {
            let error = ASExtensionError(.userInteractionRequired)
            cancelAutoFill(reason: error.code)
            throw error
        }

        let ids = try IDs.deserializeBase64(recordIdentifier)

        guard let itemContent = try await itemRepository.getItemContent(shareId: ids.shareId,
                                                                        itemId: ids.itemId),
            let logInData = itemContent.loginItem else {
            let error = ASExtensionError(.credentialIdentityNotFound)
            cancelAutoFill(reason: error.code)
            throw error
        }
        return (itemContent, logInData)
    }
}
