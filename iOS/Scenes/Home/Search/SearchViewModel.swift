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

protocol SearchViewModelDelegate: AnyObject {
    func searchViewModelWantsToShowLoadingHud()
    func searchViewModelWantsToHideLoadingHud()
    func searchViewModelWantsToDismiss()
    func searchViewModelWantsToShowItemDetail(_ item: ItemContent)
    func searchViewModelWantsToEditItem(_ item: ItemContent)
    func searchViewModelWantsToCopy(text: String, bannerMessage: String)
    func searchViewModelDidTrashItem(_ item: ItemIdentifiable, type: ItemContentType)
    func searchViewModelDidFail(_ error: Error)
}

final class SearchViewModel: DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    // Injected properties
    private let symmetricKey: SymmetricKey
    private let itemRepository: ItemRepositoryProtocol
    private let vaultSelection: VaultSelection
    private let logger: Logger

    // Self-initialized properties
    private let searchTermSubject = PassthroughSubject<String, Never>()
    private var lastTask: Task<Void, Never>?
    private var items = [SearchableItem]()

    private var lastSearchTerm = ""
    @Published private(set) var state = State.clean
    @Published private(set) var results = [ItemSearchResult]()

    /// Grouped by vault name
    var groupedResults: [String: [ItemSearchResult]] {
        Dictionary(grouping: results, by: { $0.vaultName })
    }

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: SearchViewModelDelegate?

    enum State: Equatable {
        case clean
        /// Loading items to memory
        case initializing
        case searching
        case results
        case error(Error)

        static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.clean, .clean),
                (.initializing, .initializing),
                (.searching, .searching),
                (.results, .results):
                return true
            case let (.error(lhsError), .error(rhsError)):
                return lhsError.messageForTheUser == rhsError.messageForTheUser
            default:
                return false
            }
        }
    }

    init(symmetricKey: SymmetricKey,
         itemRepository: ItemRepositoryProtocol,
         vaultSelection: VaultSelection,
         logManager: LogManager) {
        self.symmetricKey = symmetricKey
        self.itemRepository = itemRepository
        self.vaultSelection = vaultSelection
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)

        Task {
            await loadItems()
        }
        searchTermSubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [unowned self] term in
                self.doSearch(term: term)
            }
            .store(in: &cancellables)
    }

    @MainActor
    func refreshResults() async {
        await loadItems()
        doSearch(term: lastSearchTerm)
    }

    @MainActor
    private func loadItems() async {
        do {
            state = .initializing
            print("Initializing SearchViewModel")
            let items = try await itemRepository.getItems(forceRefresh: false, state: .active)
            let getVaultName: (String) -> String = { shareId in
                let vault = self.vaultSelection.vaults.first { $0.shareId == shareId }
                return vault?.name ?? ""
            }
            self.items = try items.map { try SearchableItem(symmetricallyEncryptedItem: $0,
                                                            vaultName: getVaultName($0.shareId)) }
            state = .clean
            print("Initialized SearchViewModel")
        } catch {
            logger.error(error)
            state = .error(error)
        }
    }

    private func doSearch(term: String) {
        lastSearchTerm = term
        let term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        if term.isEmpty { state = .clean; return }

        lastTask?.cancel()
        lastTask = Task { @MainActor in
            do {
                state = .searching
                results = try items.result(for: term, symmetricKey: symmetricKey)
                state = .results
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }
}

// MARK: - Private supporting tasks
private extension SearchViewModel {
    func getDecryptedItemContentTask(for item: ItemSearchResult) -> Task<ItemContent, Error> {
        Task.detached(priority: .userInitiated) {
            let encryptedItem = try await self.getItem(shareId: item.shareId, itemId: item.itemId)
            return try encryptedItem.getDecryptedItemContent(symmetricKey: self.symmetricKey)
        }
    }

    func trashItemTask(for item: ItemSearchResult) -> Task<Void, Error> {
        Task.detached(priority: .userInitiated) {
            let itemToBeTrashed = try await self.getItem(shareId: item.shareId, itemId: item.itemId)
            try await self.itemRepository.trashItems([itemToBeTrashed])
        }
    }

    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem {
        guard let item = try await itemRepository.getItem(shareId: shareId,
                                                          itemId: itemId) else {
            throw VaultContentViewModelError.itemNotFound(shareId: shareId, itemId: itemId)
        }
        return item
    }
}

// MARK: - Public actions
extension SearchViewModel {
    func dismiss() {
        delegate?.searchViewModelWantsToDismiss()
    }

    func search(term: String) {
        searchTermSubject.send(term)
    }

    func selectItem(_ item: ItemSearchResult) {
        Task { @MainActor in
            do {
                let itemContent = try await getDecryptedItemContentTask(for: item).value
                delegate?.searchViewModelWantsToShowItemDetail(itemContent)
            } catch {
                logger.error(error)
                delegate?.searchViewModelDidFail(error)
            }
        }
    }

    func editItem(_ item: ItemSearchResult) {
        Task { @MainActor in
            do {
                let itemContent = try await getDecryptedItemContentTask(for: item).value
                delegate?.searchViewModelWantsToEditItem(itemContent)
            } catch {
                logger.error(error)
                delegate?.searchViewModelDidFail(error)
            }
        }
    }

    func copyNote(_ item: ItemSearchResult) {
        guard case .note = item.type else { return }
        Task { @MainActor in
            do {
                let itemContent = try await getDecryptedItemContentTask(for: item).value
                if case .note = itemContent.contentData {
                    delegate?.searchViewModelWantsToCopy(text: itemContent.note,
                                                         bannerMessage: "Note copied")
                }
            } catch {
                logger.error(error)
                delegate?.searchViewModelDidFail(error)
            }
        }
    }

    func copyUsername(_ item: ItemSearchResult) {
        guard case .login = item.type else { return }
        Task { @MainActor in
            do {
                let itemContent = try await getDecryptedItemContentTask(for: item).value
                if case let .login(username, _, _) = itemContent.contentData {
                    delegate?.searchViewModelWantsToCopy(text: username,
                                                         bannerMessage: "Username copied")
                }
            } catch {
                logger.error(error)
                delegate?.searchViewModelDidFail(error)
            }
        }
    }

    func copyPassword(_ item: ItemSearchResult) {
        guard case .login = item.type else { return }
        Task { @MainActor in
            do {
                let itemContent = try await getDecryptedItemContentTask(for: item).value
                if case let .login(_, password, _) = itemContent.contentData {
                    delegate?.searchViewModelWantsToCopy(text: password,
                                                         bannerMessage: "Password copied")
                }
            } catch {
                logger.error(error)
                delegate?.searchViewModelDidFail(error)
            }
        }
    }

    func copyEmailAddress(_ item: ItemSearchResult) {
        guard case .alias = item.type else { return }
        Task { @MainActor in
            do {
                let item = try await getItem(shareId: item.shareId, itemId: item.itemId)
                if let emailAddress = item.item.aliasEmail {
                    delegate?.searchViewModelWantsToCopy(text: emailAddress,
                                                         bannerMessage: "Email address copied")
                }
            } catch {
                logger.error(error)
                delegate?.searchViewModelDidFail(error)
            }
        }
    }

    func trashItem(_ item: ItemSearchResult) {
        Task { @MainActor in
            defer { delegate?.searchViewModelWantsToHideLoadingHud() }
            delegate?.searchViewModelWantsToShowLoadingHud()
            do {
                try await trashItemTask(for: item).value
                await refreshResults()
                delegate?.searchViewModelDidTrashItem(item, type: item.type)
            } catch {
                logger.error(error)
                delegate?.searchViewModelDidFail(error)
            }
        }
    }
}
