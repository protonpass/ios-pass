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

enum CredentialRepositoryError: Error {
    case autoFillNotEnabled
}

public protocol CredentialRepositoryProtocol {
    var itemRepository: ItemRepositoryProtocol { get }
    var credentialIdentityStore: ASCredentialIdentityStore { get }
    var symmetricKey: SymmetricKey { get }

    /// Whether the user has picked Proton Pass as AutoFill provider
    func isEnabled() async -> Bool

    /// Populate `ASCredentialIdentityStore` from login items of all shares
    func populateCredentials() async throws

    /// Remove all login items from `ASCredentialIdentityStore`
    func removeAllCredentials() async throws

    /// Get an `ASPasswordCredential` from an `ASPasswordCredentialIdentity`
    func getCredential(of identity: ASPasswordCredentialIdentity) async throws -> ASPasswordCredential?
}

public extension CredentialRepositoryProtocol {
    func isEnabled() async -> Bool {
        await getState().isEnabled
    }

    func populateCredentials() async throws {
        try await removeAllCredentials()

        var credentials = [ASPasswordCredentialIdentity]()
        let encryptedItems = try await itemRepository.getItems(forceRefresh: false, state: .active)
        for encryptedItem in encryptedItems {
            let decryptedItemContent = try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
            if case let .login(username, _, urls) = decryptedItemContent.contentData {
                for url in urls {
                    let identifier = ASCredentialServiceIdentifier(identifier: url, type: .URL)
                    let ids = CredentialIDs(shareId: decryptedItemContent.shareId,
                                            itemId: decryptedItemContent.itemId)
                    credentials.append(.init(serviceIdentifier: identifier,
                                             user: username,
                                             recordIdentifier: try ids.serializeBase64()))
                }
            }
        }

        try await credentialIdentityStore.saveCredentialIdentities(credentials)
    }

    func removeAllCredentials() async throws {
        let state = await getState()
        if state.isEnabled {
            try await credentialIdentityStore.removeAllCredentialIdentities()
        } else {
            throw CredentialRepositoryError.autoFillNotEnabled
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
