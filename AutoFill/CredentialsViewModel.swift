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
import Combine
import Core
import CryptoKit
import SwiftUI

enum CredentialsViewModelError: Error {
    case itemNotFound(shareId: String, itemId: String)
    case notLogInItem
}

struct CredentialsFetchResult {
    let searchableItems: [SearchableItem]
    let matchedItems: [ItemListUiModel]
    let notMatchedItems: [ItemListUiModel]

    var isEmpty: Bool {
        searchableItems.isEmpty && matchedItems.isEmpty && notMatchedItems.isEmpty
    }
}

protocol CredentialsViewModelDelegate: AnyObject {
    func credentialsViewModelWantsToShowLoadingHud()
    func credentialsViewModelWantsToHideLoadingHud()
    func credentialsViewModelWantsToCancel()
    func credentialsViewModelWantsToCreateLoginItem(shareId: String, url: URL?)
    func credentialsViewModelDidSelect(credential: ASPasswordCredential,
                                       item: SymmetricallyEncryptedItem,
                                       serviceIdentifiers: [ASCredentialServiceIdentifier])
    func credentialsViewModelDidFail(_ error: Error)
}

enum CredentialsViewState {
    case loading
    case loaded(CredentialsFetchResult, CredentialsViewLoadedState)
    case error(Error)
}

enum CredentialsViewLoadedState: Equatable {
    /// Empty search query
    case idle
    case searching
    case noSearchResults
    case searchResults([ItemSearchResult])

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
            (.searching, .searching),
            (.noSearchResults, .noSearchResults),
            (.searchResults, .searchResults):
            return true
        default:
            return false
        }
    }
}

final class CredentialsViewModel: ObservableObject {
    @Published private(set) var state = CredentialsViewState.loading

    private let searchTermSubject = PassthroughSubject<String, Never>()
    private var lastTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    private let itemRepository: ItemRepositoryProtocol
    private let symmetricKey: SymmetricKey
    private let serviceIdentifiers: [ASCredentialServiceIdentifier]
    let urls: [URL]

    weak var delegate: CredentialsViewModelDelegate?

    init(itemRepository: ItemRepositoryProtocol,
         symmetricKey: SymmetricKey,
         serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        self.itemRepository = itemRepository
        self.symmetricKey = symmetricKey
        self.serviceIdentifiers = serviceIdentifiers
        self.urls = serviceIdentifiers.map { $0.identifier }.compactMap { URL(string: $0) }

        fetchItems()
        searchTermSubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [unowned self] term in
                self.doSearch(term: term)
            }
            .store(in: &cancellables)
    }

    private func doSearch(term: String) {
        guard case let .loaded(fetchResult, _) = state else { return }

        let term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else {
            state = .loaded(fetchResult, .idle)
            return
        }

        lastTask?.cancel()
        lastTask = Task { @MainActor in
            do {
                state = .loaded(fetchResult, .searching)
                let searchResults = try fetchResult.searchableItems.result(for: term,
                                                                           symmetricKey: symmetricKey)
                if searchResults.isEmpty {
                    state = .loaded(fetchResult, .noSearchResults)
                } else {
                    state = .loaded(fetchResult, .searchResults(searchResults))
                }
            } catch {
                state = .error(error)
            }
        }
    }
}

// MARK: - Public actions
extension CredentialsViewModel {
    func cancel() {
        delegate?.credentialsViewModelWantsToCancel()
    }

    func fetchItems() {
        Task { @MainActor in
            do {
                if case .error = state {
                    state = .loading
                }

                let result = try await fetchCredentialsTask().value
                state = .loaded(result, .idle)
            } catch {
                state = .error(error)
            }
        }
    }

    func associateAndAutofill(item: ItemIdentifiable) {
        Task { @MainActor in
            defer { delegate?.credentialsViewModelWantsToHideLoadingHud() }
            delegate?.credentialsViewModelWantsToShowLoadingHud()
            do {
                let encryptedItem = try await getItemTask(item: item).value
                let oldContent = try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
                guard case let .login(oldUsername, oldPassword, oldUrls) = oldContent.contentData,
                      let newUrl = urls.first?.schemeAndHost else {
                    throw CredentialsViewModelError.notLogInItem
                }
                let newLoginData = ItemContentData.login(username: oldUsername,
                                                         password: oldPassword,
                                                         urls: oldUrls + [newUrl])
                let newContent = ItemContentProtobuf(name: oldContent.name,
                                                     note: oldContent.note,
                                                     data: newLoginData)
                try await itemRepository.updateItem(oldItem: encryptedItem.item,
                                                    newItemContent: newContent,
                                                    shareId: encryptedItem.shareId)
                select(item: item)
            } catch {
                state = .error(error)
            }
        }
    }

    func select(item: ItemIdentifiable) {
        Task { @MainActor in
            do {
                let (credential, item) = try await getCredentialTask(for: item).value
                delegate?.credentialsViewModelDidSelect(credential: credential,
                                                        item: item,
                                                        serviceIdentifiers: serviceIdentifiers)
            } catch {
                state = .error(error)
            }
        }
    }

    func search(term: String) {
        searchTermSubject.send(term)
    }

    func handleAuthenticationFailure() {
        delegate?.credentialsViewModelDidFail(CredentialProviderError.failedToAuthenticate)
    }

    #warning("Ask users to choose a vault")
    // https://jira.protontech.ch/browse/IDTEAM-595
    func showCreateLoginView() {
        guard case let .loaded(fetchResult, _) = state,
        let shareId = fetchResult.searchableItems.first?.shareId else { return }
        delegate?.credentialsViewModelWantsToCreateLoginItem(shareId: shareId, url: urls.first)
    }
}

// MARK: - Private supporting tasks
private extension CredentialsViewModel {
    func getItemTask(item: ItemIdentifiable) -> Task<SymmetricallyEncryptedItem, Error> {
        Task.detached(priority: .userInitiated) {
            guard let encryptedItem =
                    try await self.itemRepository.getItem(shareId: item.shareId,
                                                          itemId: item.itemId) else {
                throw CredentialsViewModelError.itemNotFound(shareId: item.shareId,
                                                             itemId: item.itemId)
            }
            return encryptedItem
        }
    }

    func fetchCredentialsTask() -> Task<CredentialsFetchResult, Error> {
        Task.detached(priority: .userInitiated) {
            let matcher = URLUtils.Matcher.default
            let encryptedItems = try await self.itemRepository.getItems(forceRefresh: false,
                                                                        state: .active)

            var searchableItems = [SearchableItem]()
            var matchedEncryptedItems = [SymmetricallyEncryptedItem]()
            var notMatchedEncryptedItems = [SymmetricallyEncryptedItem]()
            for encryptedItem in encryptedItems {
                let decryptedItemContent =
                try encryptedItem.getDecryptedItemContent(symmetricKey: self.symmetricKey)

                if case let .login(_, _, itemUrlStrings) = decryptedItemContent.contentData {
                    searchableItems.append(try SearchableItem(symmetricallyEncryptedItem: encryptedItem,
                                                              vaultName: "Vault name"))

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

            return .init(searchableItems: searchableItems,
                         matchedItems: matchedItems,
                         notMatchedItems: notMatchedItems)
        }
    }

    func getCredentialTask(for item: ItemIdentifiable)
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
