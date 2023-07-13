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
    func searchViewModelWantsDidEncounter(error: Error)
}

final class SearchViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published private(set) var state = SearchViewState.initializing
    @Published private(set) var creditCardV1 = false
    @Published var selectedType: ItemContentType?
    @Published var query = ""

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent { didSet { filterAndSortResults() } }

    // Injected properties
    private let itemRepository: ItemRepositoryProtocol
    private let logger: Logger
    private let searchEntryDatasource: LocalSearchEntryDatasourceProtocol
    private let shareRepository: ShareRepositoryProtocol
    private let symmetricKey: SymmetricKey
    private(set) var vaultSelection: VaultSelection
    let favIconRepository: FavIconRepositoryProtocol
    let itemContextMenuHandler: ItemContextMenuHandler

    // Self-intialized properties
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

    init(favIconRepository: FavIconRepositoryProtocol,
         itemContextMenuHandler: ItemContextMenuHandler,
         itemRepository: ItemRepositoryProtocol,
         logManager: LogManagerProtocol,
         searchEntryDatasource: LocalSearchEntryDatasourceProtocol,
         shareRepository: ShareRepositoryProtocol,
         featureFlagsRepository: FeatureFlagsRepositoryProtocol,
         symmetricKey: SymmetricKey,
         vaultSelection: VaultSelection) {
        self.favIconRepository = favIconRepository
        self.itemContextMenuHandler = itemContextMenuHandler
        self.itemRepository = itemRepository
        logger = .init(manager: logManager)
        self.searchEntryDatasource = searchEntryDatasource
        self.shareRepository = shareRepository
        self.symmetricKey = symmetricKey
        self.vaultSelection = vaultSelection

        setup()
        checkFeatureFlags(with: featureFlagsRepository)
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
                                                                    symmetricKey: symmetricKey,
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
        let symmetricKey = itemRepository.symmetricKey
        history = try searchEntries.compactMap { entry in
            if let item = allItems.first(where: {
                $0.shareId == entry.shareID && $0.itemId == entry.itemID
            }) {
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
            self.selectedType = nil
            let hashedQuery = query.sha256
            self.logger.trace("Searching for \"\(hashedQuery)\"")
            if Task.isCancelled {
                return
            }
            self.results = self.searchableItems.result(for: query)
            if Task.isCancelled {
                return
            }
            self.filterAndSortResults()
            self.logger.trace("Get \(self.results.count) result(s) for \"\(hashedQuery)\"")
        }
    }

    func filterAndSortResults() {
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
        filteringTask?.cancel()
        filteringTask = Task { [weak self] in
            guard let self else {
                return
            }
            if Task.isCancelled {
                return
            }
            let filteredAndSortedResults = await self.sortItems(for: filteredResults)
            if Task.isCancelled {
                return
            }
            await MainActor.run {
                self.state = SearchViewState.results(ItemCount(items: self.results), filteredAndSortedResults)
            }
        }
    }

    func sortItems(for items: [ItemSearchResult]) async -> any SearchResults {
        switch selectedSortType {
        case .mostRecent:
            return await items.asyncMostRecentSortResult()
        case .alphabeticalAsc:
            return await items.asyncAlphabeticalSortResult(direction: .ascending)
        case .alphabeticalDesc:
            return await items.asyncAlphabeticalSortResult(direction: .descending)
        case .newestToOldest:
            return await items.asyncMonthYearSortResult(direction: .descending)
        case .oldestToNewest:
            return await items.asyncMonthYearSortResult(direction: .ascending)
        }
    }
}

// MARK: - Public APIs

extension SearchViewModel {
    func refreshResults() {
        Task { @MainActor [weak self] in
            await self?.indexItems()
            self?.doSearch(query: self?.lastSearchQuery ?? "")
        }
    }

    func viewDetail(of item: ItemIdentifiable) {
        Task { @MainActor [weak self] in
            do {
                if let itemContent = try await self?.itemRepository.getItemContent(shareId: item.shareId,
                                                                                   itemId: item.itemId) {
                    try await self?.searchEntryDatasource.upsert(item: item, date: .now)
                    try await self?.refreshSearchHistory()
                    self?.delegate?.searchViewModelWantsToViewDetail(of: itemContent)
                }
            } catch {
                self?.delegate?.searchViewModelWantsDidEncounter(error: error)
            }
        }
    }

    func removeFromHistory(_ item: ItemIdentifiable) {
        Task { @MainActor [weak self] in
            do {
                try await self?.searchEntryDatasource.remove(item: item)
                try await self?.refreshSearchHistory()
            } catch {
                self?.delegate?.searchViewModelWantsDidEncounter(error: error)
            }
        }
    }

    func removeAllSearchHistory() {
        Task { @MainActor [weak self] in
            do {
                try await self?.searchEntryDatasource.removeAllEntries()
                try await self?.refreshSearchHistory()
            } catch {
                self?.delegate?.searchViewModelWantsDidEncounter(error: error)
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
                self?.doSearch(query: term)
            }
            .store(in: &cancellables)

        $selectedType
            .receive(on: DispatchQueue.main)
            .dropFirst()
            .sink { [weak self] _ in
                self?.filterAndSortResults()
            }
            .store(in: &cancellables)
    }

    func checkFeatureFlags(with featureFlagsRepository: FeatureFlagsRepositoryProtocol) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            do {
                let flags = try await featureFlagsRepository.getFlags()
                self.creditCardV1 = flags.creditCardV1
            } catch {
                self.logger.error(error)
            }
        }
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
            return true

        case let (.history(lhsHistory), .history(rhsHistory)):
            return lhsHistory == rhsHistory

        case let (.noResults(lhsQuery), .noResults(rhsQuery)):
            return lhsQuery == rhsQuery

        case let (.results(_, lhsResults), .results(_, rhsResults)):
            return lhsResults.hashValue == rhsResults.hashValue

        case let (.error(lhsError), .error(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
