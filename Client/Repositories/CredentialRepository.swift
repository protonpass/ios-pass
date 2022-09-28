//
// CredentialRepository.swift
// Proton Pass - Created on 28/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import CryptoKit

public protocol CredentialRepositoryProtocol {
    var itemRepository: ItemRepositoryProtocol { get }
    var credentialIdentityStore: ASCredentialIdentityStore { get }
    var symmetricKey: SymmetricKey { get }

    /// Populate `ASCredentialIdentityStore` from login items of all shares
    func populateCredentials() async throws

    /// Remove all login items from `ASCredentialIdentityStore`
    func removeAllCredentials() async throws

    /// Get an `ASPasswordCredential` from an `ASPasswordCredentialIdentity`
    func getCredential(of identity: ASPasswordCredentialIdentity) async throws -> ASPasswordCredential?
}

public extension CredentialRepositoryProtocol {
    func populateCredentials() async throws {
        try await removeAllCredentials()

        var credentials = [ASPasswordCredentialIdentity]()
        let encryptedItems = try await itemRepository.getItems(forceRefresh: false, state: .active)
        for encryptedItem in encryptedItems {
            let decryptedItemContent = try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
            if case let .login(username, _, urls) = decryptedItemContent.contentData {
                for url in urls {
                    let identifier = ASCredentialServiceIdentifier(identifier: url, type: .URL)
                    credentials.append(.init(serviceIdentifier: identifier,
                                             user: username,
                                             recordIdentifier: decryptedItemContent.itemId))
                }
            }
        }

        try await credentialIdentityStore.saveCredentialIdentities(credentials)
    }

    func removeAllCredentials() async throws {
        try await credentialIdentityStore.removeAllCredentialIdentities()
    }

    func getCredential(of identity: ASPasswordCredentialIdentity) async throws -> ASPasswordCredential? {
        let encryptedItems = try await itemRepository.getItems(forceRefresh: false, state: .active)
        if let matchedEncryptedItem =
            encryptedItems.first(where: { $0.item.itemID == identity.recordIdentifier }) {
            let decryptedItemContent = try matchedEncryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
            if case let .login(username, password, _) = decryptedItemContent.contentData {
                return .init(user: username, password: password)
            }
        }
        return nil
    }
}

public final class CredentialRepository: CredentialRepositoryProtocol {
    public let itemRepository: ItemRepositoryProtocol
    public let credentialIdentityStore: ASCredentialIdentityStore
    public let symmetricKey: SymmetricKey

    public init(itemRepository: ItemRepositoryProtocol,
                credentialIdentityStore: ASCredentialIdentityStore,
                symmetricKey: SymmetricKey) {
        self.itemRepository = itemRepository
        self.credentialIdentityStore = credentialIdentityStore
        self.symmetricKey = symmetricKey
    }
}
