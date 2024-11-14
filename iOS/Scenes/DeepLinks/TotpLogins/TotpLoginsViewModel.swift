//
//
// TotpLoginsViewModel.swift
// Proton Pass - Created on 29/01/2024.
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
//

import Client
import Combine
import Core
import Entities
import Factory
import Foundation
import Macro
import SwiftUI

typealias SectionedItemSearchResult = SectionedObjects<ItemSearchResult>

@MainActor
final class TotpLoginsViewModel: ObservableObject, Sendable {
    @Published private(set) var loading = true
    @Published private(set) var results: FetchableObject<[SectionedItemSearchResult]> = .fetching
    @Published var query = ""
    @Published var showAlert = false
    @Published private(set) var shouldDismiss = false

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent {
        didSet {
            sortResults(query: nil)
        }
    }

    @LazyInjected(\SharedUseCasesContainer.getMainVault) private var getMainVault
    @LazyInjected(\SharedServiceContainer.userManager) private var userManager
    private let getActiveLoginItems = resolve(\SharedUseCasesContainer.getActiveLoginItems)
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let shareRepository = resolve(\SharedRepositoryContainer.shareRepository)
    let totpManager = resolve(\SharedServiceContainer.totpManager)

    @LazyInjected(\SharedRouterContainer.mainUIKitSwiftUIRouter) private var router
    @LazyInjected(\SharedToolingContainer.logger) private var logger

    private var searchableItems = [SearchableItem]()
    private(set) var selectedItem: ItemContent?
    let totpUri: String
    private var cancellables = Set<AnyCancellable>()

    private var sortTask: Task<Void, Never>?

    init(totpUri: String) {
        self.totpUri = totpUri
        totpManager.bind(uri: totpUri)
        setUp()
    }

    nonisolated func loadLogins() async {
        await MainActor.run { [weak self] in
            guard let self else { return }
            loading = true
        }

        do {
            let userId = try await userManager.getActiveUserId()
            async let getLogins = try getActiveLoginItems(userId: userId)
            async let getVaults = try shareRepository.getVaults(userId: userId)

            let (logins, vaults) = try await (getLogins, getVaults)

            let searchableItems = logins.map { SearchableItem(from: $0, allVaults: vaults) }

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.searchableItems = searchableItems
                loading = false
            }
            await sortResultsAsync(query: nil)
        } catch {
            await handle(error)
        }
    }

    func updateLogin(item: ItemSearchResult) {
        Task { [weak self] in
            guard let self,
                  let itemContent = try? await itemRepository.getItemContent(shareId: item.shareId,
                                                                             itemId: item.itemId) else {
                return
            }

            selectedItem = itemContent
            showAlert = true
        }
    }

    func clearSearch() {
        query = ""
    }

    func createLogin() {
        Task { [weak self] in
            guard let self else {
                return
            }

            let shareId = await getMainVault()?.shareId ?? ""
            let creationType = ItemCreationType.login(totpUri: totpUri, autofill: false)
            router.present(for: .createEditLogin(mode: .create(shareId: shareId, type: creationType)))
        }
    }

    func saveChange() {
        Task { [weak self] in
            guard let self,
                  let selectedItem else {
                return
            }
            defer { loading = false }
            do {
                loading = true
                let userId = try await userManager.getActiveUserId()
                try await itemRepository.updateItem(userId: userId,
                                                    oldItem: selectedItem.item,
                                                    newItemContent: selectedItem.updateTotp(uri: totpUri).protobuf,
                                                    shareId: selectedItem.shareId)
                if let token = totpManager.totpData?.code {
                    copyTotpToken(token)
                }
                shouldDismiss = true
            } catch {
                handle(error)
            }
        }
    }

    func copyTotpToken(_ token: String) {
        router.action(.copyToClipboard(text: token, message: #localized("TOTP copied")))
    }
}

private extension TotpLoginsViewModel {
    func setUp() {
        cleanedQuery
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] query in
                guard let self else { return }
                sortResults(query: query)
            }
            .store(in: &cancellables)
    }

    var cleanedQuery: AnyPublisher<String, Never> {
        $query
            .dropFirst()
            .debounce(for: 0.4, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .eraseToAnyPublisher()
    }

    func sortResults(query: String?) {
        sortTask?.cancel()
        sortTask = Task { [weak self] in
            guard let self else { return }
            await sortResultsAsync(query: query)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity
    nonisolated func sortResultsAsync(query: String?) async {
        do {
            await MainActor.run { [weak self] in
                guard let self else { return }
                self.results = .fetching
            }

            let searchableItems = await searchableItems
            let filteredResults = if let query, !query.isEmpty {
                try await searchableItems.result(for: query)
            } else {
                searchableItems.toItemSearchResults
            }

            let sortType = await selectedSortType
            let results: [SectionedItemSearchResult]
            switch await selectedSortType {
            case .mostRecent:
                let sortedResult = try filteredResults.mostRecentSortResult()
                results = sortedResult.buckets.compactMap { bucket in
                    guard !bucket.items.isEmpty else { return nil }
                    return .init(id: bucket.id,
                                 sectionTitle: bucket.type.title,
                                 items: bucket.items)
                }

            case .alphabeticalAsc, .alphabeticalDesc:
                let sortedResult = try filteredResults.alphabeticalSortResult(direction: sortType.sortDirection)
                results = sortedResult.buckets.compactMap { bucket in
                    guard !bucket.items.isEmpty else { return nil }
                    return .init(id: bucket.letter.character,
                                 sectionTitle: bucket.letter.character,
                                 items: bucket.items)
                }

            case .newestToOldest, .oldestToNewest:
                let sortedResult = try filteredResults.monthYearSortResult(direction: sortType.sortDirection)
                results = sortedResult.buckets.compactMap { bucket in
                    guard !bucket.items.isEmpty else { return nil }
                    return .init(id: bucket.monthYear.relativeString,
                                 sectionTitle: bucket.monthYear.relativeString,
                                 items: bucket.items)
                }
            }

            await MainActor.run { [weak self] in
                guard let self else { return }
                self.results = .fetched(results)
            }
        } catch {
            if error is CancellationError { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                results = .error(error)
            }
        }
    }

    func handle(_ error: any Error) {
        if error is CancellationError { return }
        logger.error(error)
        router.display(element: .displayErrorBanner(error))
    }
}
