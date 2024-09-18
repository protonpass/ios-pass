//
// GetItemsForOneTimeCodeAutoFill.swift
// Proton Pass - Created on 18/09/2024.
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
import UseCases

protocol GetItemsForOneTimeCodeAutoFillUseCase: Sendable {
    func execute(userId: String, identifiers: [ASCredentialServiceIdentifier])
        async throws -> CredentialsForOneTimeCodeAutoFill
}

extension GetItemsForOneTimeCodeAutoFillUseCase {
    func callAsFunction(userId: String, identifiers: [ASCredentialServiceIdentifier])
        async throws -> CredentialsForOneTimeCodeAutoFill {
        try await execute(userId: userId, identifiers: identifiers)
    }
}

final class GetItemsForOneTimeCodeAutoFill: GetItemsForOneTimeCodeAutoFillUseCase {
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let accessRepository: any AccessRepositoryProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let shareRepository: any ShareRepositoryProtocol
    private let matchUrls: any MatchUrlsUseCase
    private let mapServiceIdentifierToURL: any MapASCredentialServiceIdentifierToURLUseCase

    init(symmetricKeyProvider: any SymmetricKeyProvider,
         accessRepository: any AccessRepositoryProtocol,
         itemRepository: any ItemRepositoryProtocol,
         shareRepository: any ShareRepositoryProtocol,
         matchUrls: any MatchUrlsUseCase,
         mapServiceIdentifierToURL: any MapASCredentialServiceIdentifierToURLUseCase) {
        self.symmetricKeyProvider = symmetricKeyProvider
        self.accessRepository = accessRepository
        self.itemRepository = itemRepository
        self.shareRepository = shareRepository
        self.matchUrls = matchUrls
        self.mapServiceIdentifierToURL = mapServiceIdentifierToURL
    }
}

extension GetItemsForOneTimeCodeAutoFill {
    func execute(userId: String, identifiers: [ASCredentialServiceIdentifier])
        async throws -> CredentialsForOneTimeCodeAutoFill {
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        let plan = try await accessRepository.getPlan(userId: userId)
        let vaults = try await shareRepository.getVaults(userId: userId)
        let encryptedItems = try await itemRepository.getActiveLogInItems(userId: userId)

        let urls = identifiers.compactMap(mapServiceIdentifierToURL.callAsFunction)
        var searchableItems = [SearchableItem]()
        var matchedEncryptedItems = [ScoredSymmetricallyEncryptedItem]()
        var notMatchedEncryptedItems = [SymmetricallyEncryptedItem]()

        return .init(userId: userId,
                     vaults: vaults,
                     matchedItems: [],
                     notMatchedItems: [])
    }
}
