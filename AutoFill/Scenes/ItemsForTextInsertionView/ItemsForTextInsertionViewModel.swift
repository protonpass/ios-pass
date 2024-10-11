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

enum ItemsForTextInsertionViewState: Equatable {
    /// Empty search query
    case idle
    case searching
    case searchResults([ItemSearchResult])
    case loading
    case error(any Error)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.error(lhsError), .error(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        case (.idle, .idle),
             (.loading, .loading),
             (.searching, .searching),
             (.searchResults, .searchResults):
            true
        default:
            false
        }
    }
}

// Wrap UI models inside an enum to support displaying the same items
// in both history and normal sections.
// Because `UITableViewDiffableDataSource` relies on the hash value of the item to show or hide
enum ItemForTextInsertion: Hashable {
    case history(ItemUiModel)
    case normal(ItemUiModel)

    var uiModel: ItemUiModel {
        switch self {
        case let .history(uiModel):
            uiModel
        case let .normal(uiModel):
            uiModel
        }
    }
}

typealias ItemsForTextInsertionSection = TableView<ItemForTextInsertion, GenericCredentialItemRow, Text>.Section

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

    @LazyInjected(\SharedRepositoryContainer.localItemTextAutoFillDatasource)
    private var localItemTextAutoFillDatasource

    private let sortTypeUpdated = PassthroughSubject<Void, Never>()
    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var sortType = SortType.mostRecent {
        didSet {
            sortTypeUpdated.send(())
        }
    }

    private let filterOptionUpdated = PassthroughSubject<Void, Never>()
    @AppStorage(Constants.filterTypeKey, store: kSharedUserDefaults)
    var filterOption = ItemTypeFilterOption.all {
        didSet {
            filterOptionUpdated.send(())
        }
    }

    private var searchableItems: [SearchableItem] {
        if let selectedUser {
            results.first { $0.userId == selectedUser.id }?.searchableItems ?? []
        } else {
            getAllObjects(\.searchableItems)
        }
    }

    private var vaults: [Vault] {
        results.flatMap(\.vaults)
    }

    var highlighted: Bool {
        filterOption != .all
    }

    var resettable: Bool {
        filterOption != .all || sortType != .mostRecent
    }

    let selectedTextStream = SelectedTextStream()

    override func setUp() {
        super.setUp()
        Publishers.Merge3(selectedUserUpdated, sortTypeUpdated, filterOptionUpdated)
            .sink { [weak self] _ in
                guard let self else { return }
                filterAndSortItems()
            }
            .store(in: &cancellables)

        selectedTextStream
            .sink { [weak self] text in
                guard let self else { return }
                autofill(text)
            }
            .store(in: &cancellables)
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

    override func changeToLoadedState() {
        state = .idle
    }
}

extension ItemsForTextInsertionViewModel {
    func filterAndSortItems() {
        defer { state = .idle }
        state = .loading

        let history: [ItemUiModel]
        let allItems: [ItemUiModel]
        if let selectedUser {
            let result = results.first { $0.userId == selectedUser.id }
            history = result?.history.map(\.value) ?? []
            allItems = result?.items ?? []
        } else {
            history = Array(getAllObjects(\.history)
                .sorted(by: { $0.time > $1.time })
                .map(\.value)
                .prefix(Constants.textAutoFillHistoryLimit))
            allItems = getAllObjects(\.items)
        }

        let filteredItems = if case let .precise(type) = filterOption {
            allItems.filter { $0.type == type }
        } else {
            allItems
        }

        var sections: [ItemsForTextInsertionSection] = {
            switch sortType {
            case .mostRecent:
                let results = filteredItems.mostRecentSortResult()
                return [
                    .init(title: #localized("Today"),
                          items: results.today.map { ItemForTextInsertion.normal($0) }),
                    .init(title: #localized("Yesterday"),
                          items: results.yesterday.map { ItemForTextInsertion.normal($0) }),
                    .init(title: #localized("Last week"),
                          items: results.last7Days.map { ItemForTextInsertion.normal($0) }),
                    .init(title: #localized("Last two weeks"),
                          items: results.last14Days.map { ItemForTextInsertion.normal($0) }),
                    .init(title: #localized("Last 30 days"),
                          items: results.last30Days.map { ItemForTextInsertion.normal($0) }),
                    .init(title: #localized("Last 60 days"),
                          items: results.last60Days.map { ItemForTextInsertion.normal($0) }),
                    .init(title: #localized("Last 90 days"),
                          items: results.last90Days.map { ItemForTextInsertion.normal($0) }),
                    .init(title: #localized("More than 90 days"),
                          items: results.others.map { ItemForTextInsertion.normal($0) })
                ]

            case .alphabeticalAsc:
                let results = filteredItems.alphabeticalSortResult(direction: .ascending)
                return results.buckets.map { bucket in
                    .init(title: bucket.letter.character,
                          items: bucket.items.map { ItemForTextInsertion.normal($0) })
                }

            case .alphabeticalDesc:
                let results = filteredItems.alphabeticalSortResult(direction: .descending)
                return results.buckets.map { bucket in
                    .init(title: bucket.letter.character,
                          items: bucket.items.map { ItemForTextInsertion.normal($0) })
                }

            case .newestToOldest:
                let results = filteredItems.monthYearSortResult(direction: .descending)
                return results.buckets.map { bucket in
                    .init(title: bucket.monthYear.relativeString,
                          items: bucket.items.map { ItemForTextInsertion.normal($0) })
                }

            case .oldestToNewest:
                let results = filteredItems.monthYearSortResult(direction: .ascending)
                return results.buckets.map { bucket in
                    .init(title: bucket.monthYear.relativeString,
                          items: bucket.items.map { ItemForTextInsertion.normal($0) })
                }
            }
        }()

        // Only show history section when not filtering by item types
        if filterOption == .all, !history.isEmpty {
            sections.insert(.init(title: "History",
                                  items: history.map { ItemForTextInsertion.history($0) }),
                            at: 0)
        }

        itemCount = .init(items: allItems)
        self.sections = sections.filter { !$0.items.isEmpty }
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
        sortType = .mostRecent
    }

    func autofill(_ text: SelectedText) {
        guard #available(iOS 18, *) else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                await context?.completeRequest(withTextToInsert: text.value)
                let user = try getUser(for: text.item)
                try await localItemTextAutoFillDatasource.upsert(item: text.item,
                                                                 userId: user.id,
                                                                 date: .now)
            } catch {
                logger.error(error)
            }
        }
    }
}
