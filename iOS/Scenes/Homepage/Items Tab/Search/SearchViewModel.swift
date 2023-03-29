//
// SearchViewModel.swift
// Proton Pass - Created on 13/03/2023.
// Copyright (c) 2023 Proton Technologies AG
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

enum SearchViewState {
    /// Indexing items
    case initializing
    /// No history, empty search query
    case empty
    /// Non-empty history
    case history([SearchEntryUiModel])
    /// No results for the given search query
    case noResults(String)
    /// Results with a given search query
    case results(ItemCount, [ItemSearchResult])
    /// Error
    case error(Error)
}

protocol SearchViewModelDelegate: AnyObject {
    func searchViewModelWantsToViewDetail(of itemContent: ItemContent)
    func searchViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                   delegate: SortTypeListViewModelDelegate)
    func searchViewModelWantsDidEncounter(error: Error)
}

final class SearchViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var state = SearchViewState.initializing
    @Published var selectedType: ItemContentType?
    @Published var selectedSortType = SortType.mostRecent

    // Injected properties
    private let itemRepository: ItemRepositoryProtocol
    private let logger: Logger
    private let searchEntryDatasource: LocalSearchEntryDatasourceProtocol
    private let symmetricKey: SymmetricKey
    private(set) var vaultSelection: VaultSelection
    let itemContextMenuHandler: ItemContextMenuHandler

    // Self-intialized properties
    private var lastSearchQuery = ""
    private let searchQuerySubject = PassthroughSubject<String, Never>()
    private var lastTask: Task<Void, Never>?
    private var allItems = [SymmetricallyEncryptedItem]()
    private var searchableItems = [SearchableItem]()
    private var history = [SearchEntryUiModel]()
    private var results = [ItemSearchResult]()

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: SearchViewModelDelegate?

    var searchBarPlaceholder: String { vaultSelection.searchBarPlacehoder }

    init(itemContextMenuHandler: ItemContextMenuHandler,
         itemRepository: ItemRepositoryProtocol,
         logManager: LogManager,
         searchEntryDatasource: LocalSearchEntryDatasourceProtocol,
         symmetricKey: SymmetricKey,
         vaultSelection: VaultSelection) {
        self.itemContextMenuHandler = itemContextMenuHandler
        self.itemRepository = itemRepository
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
        self.searchEntryDatasource = searchEntryDatasource
        self.symmetricKey = symmetricKey
        self.vaultSelection = vaultSelection

        searchQuerySubject
            .debounce(for: .seconds(0.3), scheduler: DispatchQueue.main)
            .sink { [unowned self] term in
                self.doSearch(query: term)
            }
            .store(in: &cancellables)

        $selectedType
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [unowned self] _ in
                self.filterResults()
            }
            .store(in: &cancellables)

        $selectedSortType
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [unowned self] _ in
                self.filterResults()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private APIs
private extension SearchViewModel {
    func indexItems() async {
        do {
            if case .error = state {
                state = .initializing
            }

            switch vaultSelection {
            case .all:
                allItems = try await itemRepository.getItems(state: .active)
            case .precise(let vault):
                allItems = try await itemRepository.getItems(shareId: vault.shareId, state: .active)
            case .trash:
                allItems = try await itemRepository.getItems(state: .trashed)
            }
            searchableItems = try allItems.map { try SearchableItem(from: $0, symmetricKey: symmetricKey) }
            try await refreshSearchHistory()
        } catch {
            state = .error(error)
        }
    }

    @MainActor
    func refreshSearchHistory() async throws {
        var shareId: String?
        if case .precise(let vault) = vaultSelection {
            shareId = vault.shareId
        }

        let searchEntries = try await searchEntryDatasource.getAllEntries(shareId: shareId)
        let symmetricKey = itemRepository.symmetricKey
        history = try searchEntries.compactMap { entry in
            if let item = allItems.first(where: {
                $0.shareId == entry.shareID && $0.itemId == entry.itemID }) {
                return try item.toSearchEntryUiModel(symmetricKey)
            } else {
                return nil
            }
        }

        switch state {
        case .history:
            if history.isEmpty {
                state = .empty
            } else {
                state = .history(history)
            }
        default:
            break
        }
    }

    func doSearch(query: String) {
        lastSearchQuery = query
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            if history.isEmpty {
                state = .empty
            } else {
                state = .history(history)
            }
            return
        }

        lastTask?.cancel()
        lastTask = Task { @MainActor in
            selectedType = nil
            let hashedQuery = query.sha256Hashed()
            logger.trace("Searching for \"\(hashedQuery)\"")
            results = searchableItems.result(for: query)
            filterResults()
            logger.trace("Get \(results.count) result(s) for \"\(hashedQuery)\"")
        }
    }

    func filterResults() {
        guard !results.isEmpty else {
            state = .noResults(lastSearchQuery)
            return
        }

        let filteredResults: [ItemSearchResult]
        if let selectedType {
            filteredResults = results.filter { $0.type == selectedType }
        } else {
            filteredResults = results
        }

        self.state = .results(.init(items: results), filteredResults)
    }
}

// MARK: - Public APIs
extension SearchViewModel {
    func refreshResults() {
        Task { @MainActor in
            await indexItems()
            doSearch(query: lastSearchQuery)
        }
    }

    func search(_ term: String) {
        searchQuerySubject.send(term)
    }

    func viewDetail(of item: ItemIdentifiable) {
        Task { @MainActor in
            do {
                if let itemContent =
                    try await itemRepository.getDecryptedItemContent(shareId: item.shareId,
                                                                     itemId: item.itemId) {
                    try await searchEntryDatasource.upsert(item: item, date: .now)
                    try await refreshSearchHistory()
                    delegate?.searchViewModelWantsToViewDetail(of: itemContent)
                }
            } catch {
                delegate?.searchViewModelWantsDidEncounter(error: error)
            }
        }
    }

    func removeFromHistory(_ item: ItemIdentifiable) {
        Task { @MainActor in
            do {
                try await searchEntryDatasource.remove(item: item)
                try await refreshSearchHistory()
            } catch {
                delegate?.searchViewModelWantsDidEncounter(error: error)
            }
        }
    }

    func removeAllSearchHistory() {
        Task { @MainActor in
            do {
                try await searchEntryDatasource.removeAllEntries()
                try await refreshSearchHistory()
            } catch {
                delegate?.searchViewModelWantsDidEncounter(error: error)
            }
        }
    }

    func presentSortTypeList() {
        delegate?.searchViewModelWantsToPresentSortTypeList(selectedSortType: selectedSortType,
                                                            delegate: self)
    }

    func searchInAllVaults() {
        vaultSelection = .all
        Task { await refreshResults() }
    }
}

// MARK: - SortTypeListViewModelDelegate
extension SearchViewModel: SortTypeListViewModelDelegate {
    func sortTypeListViewDidSelect(_ sortType: SortType) {
        selectedSortType = sortType
    }
}

extension SearchViewState: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.initializing, .initializing), (.empty, .empty):
            return true

        case let (.history(lhsHistory), .history(rhsHistory)):
            return lhsHistory == rhsHistory

        case let (.noResults(lhsQuery), .noResults(rhsQuery)):
            return lhsQuery == rhsQuery

        case let (.results(_, lhsResults), .results(_, rhsResults)):
            return lhsResults.hashValue == rhsResults.hashValue

        case let (.error(lhsError), .error(rhsError)):
            return lhsError.messageForTheUser == rhsError.messageForTheUser
        default:
            return false
        }
    }
}
