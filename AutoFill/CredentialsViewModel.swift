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

    func fetchItems() {
        Task { @MainActor in
            do {
                state = .loading
                let matcher = URLUtils.Matcher.default
                let encryptedItems = try await itemRepository.getItems(forceRefresh: false, state: .active)

                var matchedEncryptedItems = [SymmetricallyEncryptedItem]()
                var notMatchedEncryptedItems = [SymmetricallyEncryptedItem]()
                for encryptedItem in encryptedItems {
                    let decryptedItemContent =
                    try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)

                    if case let .login(_, _, itemUrlStrings) = decryptedItemContent.contentData {
                        let itemUrls = itemUrlStrings.compactMap { URL(string: $0) }
                        let matchedUrls = urls.filter { url in
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

                self.matchedItems = try await matchedEncryptedItems.sorted()
                    .parallelMap { try await $0.toItemListUiModel(self.symmetricKey) }
                self.notMatchedItems = try await notMatchedEncryptedItems.sorted()
                    .parallelMap { try await $0.toItemListUiModel(self.symmetricKey) }
                state = .loaded
            } catch {
                state = .error(error)
            }
        }
    }
}

// MARK: - Actions
extension CredentialsViewModel {
    func closeAction() {
        onClose?()
    }

    func select(item: ItemListUiModel) {
        Task { @MainActor in
            do {
                guard let item = try await itemRepository.getItem(shareId: item.shareId,
                                                                  itemId: item.itemId) else {
                    return
                }
                let itemContent = try item.getDecryptedItemContent(symmetricKey: symmetricKey)
                switch itemContent.contentData {
                case let .login(username, password, _):
                    onSelect?(.init(user: username, password: password), item)
                default:
                    break
                }
            } catch {
                state = .error(error)
            }
        }
    }
}
