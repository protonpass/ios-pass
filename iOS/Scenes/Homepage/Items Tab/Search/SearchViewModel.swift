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
    case initializing
    case clean
    case results
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
    @Published private(set) var itemCount = ItemCount.zero
    @Published var selectedType: ItemContentType?
    @Published var selectedSortType = SortType.mostRecent
    @Published private(set) var results = [ItemSearchResult]()
    /// All the results that match `selectedType`
    @Published private(set) var filteredResults = [ItemSearchResult]()
    @Published private(set) var searchEntries = [SearchEntryUiModel]()

    // Injected properties
    private let itemRepository: ItemRepositoryProtocol
    private let logger: Logger
    private let searchEntryDatasource: LocalSearchEntryDatasourceProtocol
    private let symmetricKey: SymmetricKey
    private(set) var vaultSelection: VaultSelection

    // Self-intialized properties
    private var lastSearchTerm = ""
    private let searchTermSubject = PassthroughSubject<String, Never>()
    private var lastTask: Task<Void, Never>?
    private var searchableItems = [SearchableItem]()

    private var cancellables = Set<AnyCancellable>()

    weak var delegate: SearchViewModelDelegate?

    var searchBarPlaceholder: String { vaultSelection.searchBarPlacehoder }

    init(itemRepository: ItemRepositoryProtocol,
         logManager: LogManager,
         searchEntryDatasource: LocalSearchEntryDatasourceProtocol,
         symmetricKey: SymmetricKey,
         vaultSelection: VaultSelection) {
        self.itemRepository = itemRepository
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
        self.searchEntryDatasource = searchEntryDatasource
        self.symmetricKey = symmetricKey
        self.vaultSelection = vaultSelection

        Task { await loadItems() }

        searchTermSubject
            .debounce(for: .seconds(0.5), scheduler: DispatchQueue.main)
            .sink { [unowned self] term in
                self.doSearch(term: term)
            }
            .store(in: &cancellables)

        $selectedType
            .receive(on: RunLoop.main)
            .sink { [unowned self] _ in
                self.filterResults()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Private APIs
private extension SearchViewModel {
    func doSearch(term: String) {
        lastSearchTerm = term
        let term = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { state = .clean; return }

        lastTask?.cancel()
        lastTask = Task { @MainActor in
            do {
                selectedType = nil
                let hashedTerm = term.sha256Hashed()
                logger.trace("Searching for \"\(hashedTerm)\"")
                results = try searchableItems.result(for: term, symmetricKey: symmetricKey)
                itemCount = .init(items: results)
                filterResults()
                state = .results
                logger.trace("Get \(results.count) result(s) for \"\(hashedTerm)\"")
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }

    func filterResults() {
        if let selectedType {
            filteredResults = results.filter { $0.type == selectedType }
        } else {
            filteredResults = results
        }
    }
}

// MARK: - Public APIs
extension SearchViewModel {
    @MainActor
    func loadItems() async {
        do {
            if case .error = state {
                state = .initializing
            }

            let allActiveItems = try await itemRepository.getItems(state: .active)
            let filteredActiveItems: [SymmetricallyEncryptedItem]
            switch vaultSelection {
            case .all:
                filteredActiveItems = allActiveItems
            case .precise(let vault):
                filteredActiveItems = allActiveItems.filter { $0.shareId == vault.shareId }
            }
            searchableItems =
            try filteredActiveItems.map { try SearchableItem(from: $0) }
            state = .clean
        } catch {
            state = .error(error)
        }
    }

    @MainActor
    func refreshResults() async {
        await loadItems()
        doSearch(term: lastSearchTerm)
    }

    func search(_ term: String) {
        doSearch(term: term)
    }

    func viewDetail(of result: ItemSearchResult) {
        Task { @MainActor in
            do {
                if let itemContent =
                    try await itemRepository.getDecryptedItemContent(shareId: result.shareId,
                                                                     itemId: result.itemId) {
                    delegate?.searchViewModelWantsToViewDetail(of: itemContent)
                }
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
        case (.initializing, .initializing),
            (.clean, .clean):
            return true
        case let (.error(lhsError), .error(rhsError)):
            return lhsError.messageForTheUser == rhsError.messageForTheUser
        default:
            return false
        }
    }
}
