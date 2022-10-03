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
import Core
import CryptoKit

public enum CredentialRepositoryError: Error {
    case notLogInItems
}

public protocol CredentialRepositoryProtocol {
    var itemRepository: ItemRepositoryProtocol { get }
    var credentialIdentityStore: ASCredentialIdentityStore { get }
    var symmetricKey: SymmetricKey { get }

    /// Whether the user has picked Proton Pass as AutoFill provider
    func isEnabled() async -> Bool

    /// Whether there are already previous credentials in the database
    func hasCredentials() async -> Bool

    /// Populate `ASCredentialIdentityStore` from login items of all shares
    func populateCredentials() async throws

    /// Remove all login items from `ASCredentialIdentityStore`
    func removeAllCredentials() async throws

    /// Get an `ASPasswordCredential` from an `ASPasswordCredentialIdentity`
    func getCredential(of identity: ASPasswordCredentialIdentity) async throws -> ASPasswordCredential?

    /// Update a login item
    func update(oldContentData: ItemContentData,
                newContentData: ItemContentData,
                shareId: String,
                itemId: String) async throws
}

public extension CredentialRepositoryProtocol {
    func isEnabled() async -> Bool {
        await getState().isEnabled
    }

    func hasCredentials() async -> Bool {
        await getState().supportsIncrementalUpdates
    }

    func populateCredentials() async throws {
        let state = await getState()
        guard state.isEnabled else { return }
        try await removeAllCredentials()

        var credentials = [ASPasswordCredentialIdentity]()
        let encryptedItems = try await itemRepository.getItems(forceRefresh: false, state: .active)
        for encryptedItem in encryptedItems {
            let decryptedItemContent = try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
            if case let .login(username, _, urls) = decryptedItemContent.contentData {
                for url in urls {
                    let credential = try ASPasswordCredentialIdentity(username: username,
                                                                      url: url,
                                                                      shareId: decryptedItemContent.shareId,
                                                                      itemId: decryptedItemContent.itemId)
                    credentials.append(credential)
                }
            }
        }

        try await credentialIdentityStore.saveCredentialIdentities(credentials)
    }

    func removeAllCredentials() async throws {
        let state = await getState()
        if state.isEnabled {
            try await credentialIdentityStore.removeAllCredentialIdentities()
        }
    }

    func getCredential(of identity: ASPasswordCredentialIdentity) async throws -> ASPasswordCredential? {
        guard let recordIdentifier = identity.recordIdentifier else { return nil }
        let ids = try CredentialIDs.deserializeBase64(recordIdentifier)
        guard let encryptedItem = try await itemRepository.getItem(shareId: ids.shareId,
                                                                   itemId: ids.itemId) else {
            return nil
        }
        let decryptedItemContent = try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
        if case let .login(username, password, _) = decryptedItemContent.contentData {
            return .init(user: username, password: password)
        }
        return nil
    }

    func update(oldContentData: ItemContentData,
                newContentData: ItemContentData,
                shareId: String,
                itemId: String) async throws {
        guard case let .login(oldUsername, _, oldUrls) = oldContentData else {
            throw CredentialRepositoryError.notLogInItems
        }

        guard case let .login(newUsername, _, newUrls) = newContentData else {
            throw CredentialRepositoryError.notLogInItems
        }

        if await hasCredentials() {
            // First remove all old credentials
            let oldCredentials = try oldUrls.map { try ASPasswordCredentialIdentity(username: oldUsername,
                                                                                    url: $0,
                                                                                    shareId: shareId,
                                                                                    itemId: itemId)}
            try await credentialIdentityStore.removeCredentialIdentities(oldCredentials)
        }

        // Then add new credentials
        let newCredentials = try newUrls.map { try ASPasswordCredentialIdentity(username: newUsername,
                                                                                url: $0,
                                                                                shareId: shareId,
                                                                                itemId: itemId)}
        try await credentialIdentityStore.saveCredentialIdentities(newCredentials)
    }

    private func getState() async -> ASCredentialIdentityStoreState {
        await credentialIdentityStore.state()
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

private extension ASPasswordCredentialIdentity {
    convenience init(username: String,
                     url: String,
                     shareId: String,
                     itemId: String) throws {
        let ids = CredentialIDs(shareId: shareId, itemId: itemId)
        self.init(serviceIdentifier: .init(identifier: url, type: .URL),
                  user: username,
                  recordIdentifier: try ids.serializeBase64())
    }
}
