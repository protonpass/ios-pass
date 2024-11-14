//
// ItemsForTextInsertionViewModel.swift
// Proton Pass - Created on 27/09/2024.
// Copyright (c) 2024 Proton Technologies AG
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
import DesignSystem
import Entities
import Factory
import Macro
import SwiftUI

// Wrap UI models inside an enum to support displaying the same items
// in both history and regular sections.
// Because `UITableViewDiffableDataSource` relies on the hash value of the item to show or hide
enum ItemForTextInsertion: Hashable {
    case history(ItemUiModel)
    case regular(ItemUiModel)

    var uiModel: ItemUiModel {
        switch self {
        case let .history(uiModel):
            uiModel
        case let .regular(uiModel):
            uiModel
        }
    }
}

enum ItemsForTextInsertionSectionType: Hashable {
    case history, regular
}

typealias ItemsForTextInsertionSection =
    TableView<ItemForTextInsertion, GenericCredentialItemRow, TextInsertionHistoryHeaderView>.Section

@MainActor
final class ItemsForTextInsertionViewModel: AutoFillViewModel<ItemsForTextInsertion> {
    @Published private(set) var sections = [ItemsForTextInsertionSection]()
    @Published private(set) var itemCount: ItemCount = .zero
    @Published private(set) var state = CredentialsViewState.loading
    @Published var query = ""
    @Published var selectedItem: SelectedItem?

    @LazyInjected(\AutoFillUseCaseContainer.fetchItemsForTextInsertion)
    private var fetchItemsForTextInsertion

    @LazyInjected(\SharedRepositoryContainer.itemRepository)
    private var itemRepository

    @LazyInjected(\SharedRepositoryContainer.localTextAutoFillHistoryEntryDatasource)
    private var textAutoFillHistoryEntryDatasource

    @LazyInjected(\AutoFillUseCaseContainer.completeTextAutoFill)
    private var completeTextAutoFill

    // Not using @Published because sinking on a @Published is triggered before the value is set
    private let filterOptionUpdated = PassthroughSubject<Void, Never>()
    var filterOption = ItemTypeFilterOption.all {
        didSet {
            filterOptionUpdated.send(())
        }
    }

    private var searchTask: Task<Void, Never>?
    private var searchableItems: [SearchableItem] = []
    private var filterAndSortTask: Task<Void, Never>?

    private var vaults: [Vault] {
        results.flatMap(\.vaults)
    }

    var highlighted: Bool {
        !filterOption.isDefault || !selectedSortType.isDefault
    }

    var selectedItemType: ItemType?

    let selectedTextStream = SelectedTextStream()

    override func setUp() {
        super.setUp()
        Publishers.Merge3(selectedUserUpdated, sortTypeUpdated, filterOptionUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                filterAndSortItems()
            }
            .store(in: &cancellables)

        selectedTextStream
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                guard let self else { return }
                autofill(text)
            }
            .store(in: &cancellables)

        $query
            .debounce(for: 0.4, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] term in
                guard let self else { return }
                doSearch(term: term)
            }
            .store(in: &cancellables)
    }

    override nonisolated func fetchItems() async {
        await super.fetchItems()
        await filterAndSortItemsAsync()
    }

    override func getVaults(userId: String) -> [Vault]? {
        results.first { $0.userId == userId }?.vaults
    }

    override func isErrorState() -> Bool {
        if case .error = state {
            true
        } else {
            false
        }
    }

    override func fetchAutoFillCredentials(userId: String) async throws -> ItemsForTextInsertion {
        try await fetchItemsForTextInsertion(userId: userId)
    }

    override func changeToErrorState(_ error: any Error) {
        state = .error(error)
    }

    override func changeToLoadingState() {
        state = .loading
    }

    override func generateItemCreationInfo(userId: String, vaults: [Vault]) -> ItemCreationInfo {
        switch selectedItemType {
        case .login:
            return .init(userId: userId, vaults: vaults, data: .login(nil, nil))
        case .alias:
            return .init(userId: userId, vaults: vaults, data: .alias)
        default:
            assertionFailure("Only logins and aliases could be created when text autofilling")
            // Fallback to creating login
            return .init(userId: userId, vaults: vaults, data: .login(nil, nil))
        }
    }
}

private extension ItemsForTextInsertionViewModel {
    func doSearch(term: String) {
        guard !term.isEmpty else {
            state = .idle
            return
        }

        searchTask?.cancel()
        searchTask = Task { [weak self] in
            guard let self else { return }
            await searchAsync(term: term)
        }
    }

    nonisolated func searchAsync(term: String) async {
        let hashedTerm = term.sha256
        await MainActor.run { [weak self] in
            guard let self else { return }
            logger.trace("Searching for term \(hashedTerm)")
            state = .searching
        }

        do {
            let searchResults = try await searchableItems.result(for: term)
            await MainActor.run { [weak self] in
                guard let self else { return }
                state = .searchResults(searchResults)
                if searchResults.isEmpty {
                    logger.trace("No results for term \(hashedTerm)")
                } else {
                    logger.trace("Found results for term \(hashedTerm)")
                }
            }
        } catch {
            await handle(error)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    nonisolated func filterAndSortItemsAsync() async {
        let searchableItems: [SearchableItem]
        let history: [ItemUiModel]
        let allItems: [ItemUiModel]

        let results = await results
        if let selectedUser = await selectedUser,
           let result = results.first(where: { $0.userId == selectedUser.id }) {
            searchableItems = result.searchableItems
            history = result.history.map(\.value)
            allItems = result.items
        } else {
            searchableItems = await getAllObjects(\.searchableItems)
            history = await Array(getAllObjects(\.history)
                .sorted(by: { $0.time > $1.time })
                .prefix(Constants.textAutoFillHistoryLimit))
                .map(\.value)
            allItems = await getAllObjects(\.items)
        }

        let filterOption = await filterOption
        let filteredItems = if case let .precise(type) = filterOption {
            allItems.filter { $0.type == type }
        } else {
            allItems
        }

        do {
            let selectedSortType = await selectedSortType
            var sections: [ItemsForTextInsertionSection] = try {
                switch selectedSortType {
                case .mostRecent:
                    let results = try filteredItems.mostRecentSortResult()
                    return results.buckets.compactMap { bucket in
                        guard !bucket.items.isEmpty else { return nil }
                        return .init(type: ItemsForTextInsertionSectionType.regular,
                                     title: bucket.type.title,
                                     items: bucket.items.map { ItemForTextInsertion.regular($0) })
                    }

                case .alphabeticalAsc, .alphabeticalDesc:
                    let results = try filteredItems
                        .alphabeticalSortResult(direction: selectedSortType.sortDirection)
                    return results.buckets.compactMap { bucket in
                        guard !bucket.items.isEmpty else { return nil }
                        return .init(type: ItemsForTextInsertionSectionType.regular,
                                     title: bucket.letter.character,
                                     items: bucket.items.map { ItemForTextInsertion.regular($0) })
                    }

                case .newestToOldest, .oldestToNewest:
                    let results = try filteredItems
                        .monthYearSortResult(direction: selectedSortType.sortDirection)
                    return results.buckets.compactMap { bucket in
                        guard !bucket.items.isEmpty else { return nil }
                        return .init(type: ItemsForTextInsertionSectionType.regular,
                                     title: bucket.monthYear.relativeString,
                                     items: bucket.items.map { ItemForTextInsertion.regular($0) })
                    }
                }
            }()
            // Only show history section when not filtering by item types
            if filterOption == .all, !history.isEmpty {
                sections.insert(.init(type: ItemsForTextInsertionSectionType.history,
                                      title: "",
                                      items: history.map { ItemForTextInsertion.history($0) }),
                                at: 0)
            }

            let itemCount = ItemCount(items: allItems)
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.searchableItems = searchableItems
                self.itemCount = itemCount
                self.sections = sections
                switch state {
                case .searchResults:
                    break
                default:
                    state = .idle
                }
            }
        } catch {
            await handle(error)
        }
    }
}

extension ItemsForTextInsertionViewModel {
    func filterAndSortItems() {
        filterAndSortTask?.cancel()
        filterAndSortTask = Task { [weak self] in
            guard let self else { return }
            await filterAndSortItemsAsync()
        }
    }

    func select(_ item: any ItemIdentifiable) {
        Task { [weak self] in
            guard let self else { return }
            do {
                if let itemContent = try await itemRepository.getItemContent(shareId: item.shareId,
                                                                             itemId: item.itemId),
                    let vault = vaults.first(where: { $0.shareId == item.shareId }) {
                    let user = try getUser(for: item)
                    selectedItem = .init(userId: user.id,
                                         content: itemContent,
                                         vault: vault)
                }
            } catch {
                handle(error)
            }
        }
    }

    func resetFilters() {
        filterOption = .all
        selectedSortType = .mostRecent
    }

    func autofill(_ text: SelectedText) {
        guard #available(iOS 18, *) else { return }
        Task { [weak self] in
            guard let self, let context else { return }
            do {
                let user = try getUser(for: text.item)
                try await completeTextAutoFill(text.value,
                                               context: context,
                                               userId: user.id,
                                               item: text.item)
            } catch {
                logger.error(error)
            }
        }
    }

    func clearHistory() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await textAutoFillHistoryEntryDatasource.removeAll()
                results = results.map { ItemsForTextInsertion(userId: $0.userId,
                                                              vaults: $0.vaults,
                                                              history: [],
                                                              searchableItems: $0.searchableItems,
                                                              items: $0.items) }
                await filterAndSortItemsAsync()
            } catch {
                handle(error)
            }
        }
    }
}
