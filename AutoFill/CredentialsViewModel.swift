//
// CredentialsViewModel.swift
// Proton Pass - Created on 27/09/2022.
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
import Client
import Core
import CryptoKit
import SwiftUI

enum CredentialsViewModelError: Error {
    case itemNotFound(shareId: String, itemId: String)
    case notLogInItem
}

private struct CredentialsFetchResult {
    let matchedItems: [ItemListUiModel]
    let notMatchedItems: [ItemListUiModel]
}

final class CredentialsViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded
        case error(Error)
    }

    @Published private(set) var state = State.idle
    @Published private(set) var matchedItems = [ItemListUiModel]()
    @Published private(set) var notMatchedItems = [ItemListUiModel]()

    private let itemRepository: ItemRepositoryProtocol
    private let symmetricKey: SymmetricKey
    private let urls: [URL]

    var onClose: (() -> Void)?
    var onSelect: ((ASPasswordCredential, SymmetricallyEncryptedItem) -> Void)?

    init(itemRepository: ItemRepositoryProtocol,
         symmetricKey: SymmetricKey,
         serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        self.itemRepository = itemRepository
        self.symmetricKey = symmetricKey
        self.urls = serviceIdentifiers.map { $0.identifier }.compactMap { URL(string: $0) }
        fetchItems()
    }
}

// MARK: - Public actions
extension CredentialsViewModel {
    func fetchItems() {
        Task { @MainActor in
            do {
                state = .loading
                let result = try await fetchCredentialsTask().value
                self.matchedItems = result.matchedItems
                self.notMatchedItems = result.notMatchedItems
                state = .loaded
            } catch {
                state = .error(error)
            }
        }
    }

    func select(item: ItemListUiModel) {
        Task { @MainActor in
            do {
                let (credential, item) = try await getCredentialTask(item).value
                onSelect?(credential, item)
            } catch {
                state = .error(error)
            }
        }
    }
}

// MARK: - Private supporting tasks
private extension CredentialsViewModel {
    func fetchCredentialsTask() -> Task<CredentialsFetchResult, Error> {
        Task.detached(priority: .userInitiated) {
            let matcher = URLUtils.Matcher.default
            let encryptedItems = try await self.itemRepository.getItems(forceRefresh: false,
                                                                        state: .active)

            var matchedEncryptedItems = [SymmetricallyEncryptedItem]()
            var notMatchedEncryptedItems = [SymmetricallyEncryptedItem]()
            for encryptedItem in encryptedItems {
                let decryptedItemContent =
                try encryptedItem.getDecryptedItemContent(symmetricKey: self.symmetricKey)

                if case let .login(_, _, itemUrlStrings) = decryptedItemContent.contentData {
                    let itemUrls = itemUrlStrings.compactMap { URL(string: $0) }
                    let matchedUrls = self.urls.filter { url in
                        itemUrls.contains { itemUrl in
                            matcher.isMatched(itemUrl, url)
                        }
                    }

                    if matchedUrls.isEmpty {
                        notMatchedEncryptedItems.append(encryptedItem)
                    } else {
                        matchedEncryptedItems.append(encryptedItem)
                    }
                }
            }

            let matchedItems = try await matchedEncryptedItems.sorted()
                .parallelMap { try await $0.toItemListUiModel(self.symmetricKey) }
            let notMatchedItems = try await notMatchedEncryptedItems.sorted()
                .parallelMap { try await $0.toItemListUiModel(self.symmetricKey) }

            return .init(matchedItems: matchedItems, notMatchedItems: notMatchedItems)
        }
    }

    func getCredentialTask(_ item: ItemListUiModel)
    -> Task<(ASPasswordCredential, SymmetricallyEncryptedItem), Error> {
        Task.detached(priority: .userInitiated) {
            guard let item = try await self.itemRepository.getItem(shareId: item.shareId,
                                                                   itemId: item.itemId) else {
                throw CredentialsViewModelError.itemNotFound(shareId: item.shareId,
                                                             itemId: item.itemId)
            }
            let itemContent = try item.getDecryptedItemContent(symmetricKey: self.symmetricKey)

            switch itemContent.contentData {
            case let .login(username, password, _):
                let credential = ASPasswordCredential(user: username, password: password)
                return (credential, item)
            default:
                throw CredentialsViewModelError.notLogInItem
            }
        }
    }
}
