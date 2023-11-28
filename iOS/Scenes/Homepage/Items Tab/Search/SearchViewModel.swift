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
import Entities
import Factory
import SwiftUI

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
    case results(ItemCount, any SearchResults)
    /// Error
    case error(Error)
}

protocol SearchViewModelDelegate: AnyObject {
    func searchViewModelWantsToViewDetail(of itemContent: ItemContent)
    func searchViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                   delegate: SortTypeListViewModelDelegate)
}

final class SearchViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var state = SearchViewState.initializing
    @Published var selectedType: ItemContentType?
    @Published var query = ""

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent { didSet { filterAndSortResults() } }

    // Injected properties
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let shareRepository = resolve(\SharedRepositoryContainer.shareRepository)
    private let searchEntryDatasource = resolve(\SharedRepositoryContainer.localSearchEntryDatasource)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    // Self-intialized properties
    private(set) var vaultSelection: VaultSelection
    let itemContextMenuHandler = resolve(\SharedServiceContainer.itemContextMenuHandler)

    private var lastSearchQuery = ""
    private var lastTask: Task<Void, Never>?
    private var filteringTask: Task<Void, Never>?
    private var allItems = [SymmetricallyEncryptedItem]()
    private var searchableItems = [SearchableItem]()
    private var history = [SearchEntryUiModel]()
    private var results = [ItemSearchResult]()
    private var cancellables = Set<AnyCancellable>()

    weak var delegate: SearchViewModelDelegate?

    var searchBarPlaceholder: String { vaultSelection.searchBarPlacehoder }

    init(vaultSelection: VaultSelection) {
        self.vaultSelection = vaultSelection
        setup()
    }
}

// MARK: - Private APIs

private extension SearchViewModel {
    func indexItems() async {
        do {
            if case .error = state {
                state = .initializing
            }

            let vaults = try await shareRepository.getVaults()

            switch vaultSelection {
            case .all:
                allItems = try await itemRepository.getItems(state: .active)
            case let .precise(vault):
                allItems = try await itemRepository.getItems(shareId: vault.shareId, state: .active)
            case .trash:
                allItems = try await itemRepository.getItems(state: .trashed)
            }
            searchableItems = try allItems.map { try SearchableItem(from: $0,
                                                                    symmetricKey: getSymmetricKey(),
                                                                    allVaults: vaults) }
            try await refreshSearchHistory()
        } catch {
            state = .error(error)
        }
    }

    @MainActor
    func refreshSearchHistory() async throws {
        var shareId: String?
        if case let .precise(vault) = vaultSelection {
            shareId = vault.shareId
        }

        let searchEntries = try await searchEntryDatasource.getAllEntries(shareId: shareId)
        history = try searchEntries.compactMap { entry in
            if let item = allItems.first(where: {
                $0.shareId == entry.shareID && $0.itemId == entry.itemID
            }) {
                try item.toSearchEntryUiModel(getSymmetricKey())
            } else {
                nil
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
        guard !query.isEmpty else {
            if history.isEmpty {
                state = .empty
            } else {
                state = .history(history)
            }
            return
        }

        lastTask?.cancel()
        lastTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            let hashedQuery = query.sha256
            logger.trace("Searching for \"\(hashedQuery)\"")
            if Task.isCancelled {
                return
            }
            results = searchableItems.result(for: query)
            if Task.isCancelled {
                return
            }
            filterAndSortResults()
            logger.trace("Get \(self.results.count) result(s) for \"\(hashedQuery)\"")
        }
    }

    func filterAndSortResults() {
        guard !results.isEmpty else {
            state = .noResults(lastSearchQuery)
            return
        }

        let filteredResults: [ItemSearchResult] = if let selectedType {
            results.filter { $0.type == selectedType }
        } else {
            results
        }
        filteringTask?.cancel()
        filteringTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            if Task.isCancelled {
                return
            }
            let filteredAndSortedResults = await sortItems(for: filteredResults)
            if Task.isCancelled {
                return
            }
            state = SearchViewState.results(ItemCount(items: self.results), filteredAndSortedResults)
        }
    }

    func sortItems(for items: [ItemSearchResult]) async -> any SearchResults {
        switch selectedSortType {
        case .mostRecent:
            await items.asyncMostRecentSortResult()
        case .alphabeticalAsc:
            await items.asyncAlphabeticalSortResult(direction: .ascending)
        case .alphabeticalDesc:
            await items.asyncAlphabeticalSortResult(direction: .descending)
        case .newestToOldest:
            await items.asyncMonthYearSortResult(direction: .descending)
        case .oldestToNewest:
            await items.asyncMonthYearSortResult(direction: .ascending)
        }
    }
}

// MARK: - Public APIs

extension SearchViewModel {
    func refreshResults() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            await indexItems()
            doSearch(query: lastSearchQuery)
        }
    }

    func viewDetail(of item: ItemIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                if let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                             itemId: item.itemId) {
                    try await searchEntryDatasource.upsert(item: item, date: .now)
                    try await refreshSearchHistory()
                    delegate?.searchViewModelWantsToViewDetail(of: itemContent)
                }
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func removeFromHistory(_ item: ItemIdentifiable) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await searchEntryDatasource.remove(item: item)
                try await refreshSearchHistory()
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func removeAllSearchHistory() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await searchEntryDatasource.removeAllEntries()
                try await refreshSearchHistory()
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func presentSortTypeList() {
        delegate?.searchViewModelWantsToPresentSortTypeList(selectedSortType: selectedSortType,
                                                            delegate: self)
    }

    func searchInAllVaults() {
        vaultSelection = .all
        refreshResults()
    }
}

// MARK: SetUP & Utils

private extension SearchViewModel {
    func setup() {
        $query
            .debounce(for: 0.4, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] term in
                guard let self else { return }
                doSearch(query: term)
            }
            .store(in: &cancellables)

        $selectedType
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                filterAndSortResults()
            }
            .store(in: &cancellables)
    }

    func getSymmetricKey() throws -> SymmetricKey {
        try symmetricKeyProvider.getSymmetricKey()
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
        case (.empty, .empty), (.initializing, .initializing):
            true

        case let (.history(lhsHistory), .history(rhsHistory)):
            lhsHistory == rhsHistory

        case let (.noResults(lhsQuery), .noResults(rhsQuery)):
            lhsQuery == rhsQuery

        case let (.results(lhsItemCount, lhsResults), .results(rhsItemCount, rhsResults)):
            lhsResults.hashValue == rhsResults.hashValue &&
                lhsItemCount == rhsItemCount

        case let (.error(lhsError), .error(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        default:
            false
        }
    }
}
