//
// SearchViewModel.swift
// Proton Pass - Created on 09/08/2022.
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

import Client
import Combine
import Core
import CryptoKit
import SwiftUI

final class SearchViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    // Injected properties
    private let symmetricKey: SymmetricKey
    private let itemRepository: ItemRepositoryProtocol

    // Self-initialized properties
    private let searchTermSubject = PassthroughSubject<String, Never>()
    private var lastTask: Task<Void, Never>?
    private var items = [SearchableItem]()

    @Published private var term = ""
    @Published private(set) var state = State.clean
    @Published private(set) var results = [ItemSearchResult]()

    private var cancellables = Set<AnyCancellable>()

    enum State {
        case clean
        /// Loading items to memory
        case initializing
        case searching
        case results
        case error(Error)
    }

    init(symmetricKey: SymmetricKey,
         itemRepository: ItemRepositoryProtocol) {
        self.symmetricKey = symmetricKey
        self.itemRepository = itemRepository

        loadItems()
        searchTermSubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [unowned self] term in
                self.doSearch(term: term)
            }
            .store(in: &cancellables)
    }

    private func loadItems() {
        Task { @MainActor in
            do {
                state = .initializing
                print("Initializing SearchViewModel")
                let items = try await itemRepository.getItems(forceRefresh: false, state: .active)
                self.items = try items.map { try SearchableItem(symmetricallyEncryptedItem: $0) }
                state = .clean
                print("Initialized SearchViewModel")
            } catch {
                state = .error(error)
            }
        }
    }

    func search(term: String) {
        searchTermSubject.send(term)
    }

    private func doSearch(term: String) {
        let term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        if term.isEmpty { state = .clean; return }

        lastTask?.cancel()
        lastTask = Task { @MainActor in
            do {
                state = .searching
                results = try items.compactMap { try result(forItem: $0, term: term) }
                state = .results
            } catch {
                state = .error(error)
            }
        }
    }

    private func result(forItem item: SearchableItem, term: String) throws -> ItemSearchResult? {
        let decryptedName = try symmetricKey.decrypt(item.encryptedItemContent.name)
        let title: SearchResultEither
        if let result = SearchUtils.search(query: term, in: decryptedName) {
            title = .matched(result)
        } else {
            title = .notMatched(decryptedName)
        }

        var detail = [SearchResultEither]()
        let decryptedNote = try symmetricKey.decrypt(item.encryptedItemContent.note)
        if let result = SearchUtils.search(query: term, in: decryptedNote) {
            detail.append(.matched(result))
        } else {
            detail.append(.notMatched(decryptedNote))
        }

        if case let .login(username, _, urls) = item.encryptedItemContent.contentData {
            let decryptedUsername = try symmetricKey.decrypt(username)
            if let result = SearchUtils.search(query: term, in: decryptedUsername) {
                detail.append(.matched(result))
            }

            let decryptedUrls = try urls.map { try symmetricKey.decrypt($0) }
            for decryptedUrl in decryptedUrls {
                if let result = SearchUtils.search(query: term, in: decryptedUrl) {
                    detail.append(.matched(result))
                }
            }
        }

        let detailNotMatched = detail.contains { either in
            if case .matched = either {
                return false
            } else {
                return true
            }
        }

        if case .notMatched = title, detailNotMatched {
            return nil
        }

        return .init(shareId: item.shareId,
                     itemId: item.itemId,
                     type: item.encryptedItemContent.contentData.type,
                     title: title,
                     detail: detail,
                     vaultName: item.vaultName)
    }
}
