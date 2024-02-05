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

@MainActor
final class TotpLoginsViewModel: ObservableObject, Sendable {
    @Published private(set) var loading = true
    @Published private(set) var results = [ItemSearchResult]()
    @Published var query = ""
    @Published var showConfirmation = false
    @Published private(set) var shouldDismiss = false

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent

    @LazyInjected(\SharedUseCasesContainer.getMainVault) private var getMainVault
    private let getActiveLoginItems = resolve(\SharedUseCasesContainer.getActiveLoginItems)
    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    let totpManager = resolve(\ServiceContainer.totpManager)

    private var searchableItems = [SearchableItem]()
    private(set) var selectedItem: ItemContent?
    let totpUri: String
    private var cancellables = Set<AnyCancellable>()

    init(totpUri: String) {
        self.totpUri = totpUri
        totpManager.bind(uri: totpUri)
        setUp()
    }

    func loadLogins() async {
        loading = true
        defer {
            loading = false
        }

        do {
            let logins = try await getActiveLoginItems().filter { !$0.hasTotpUri }
            searchableItems = logins.map { SearchableItem(from: $0, allVaults: []) }
            results = searchableItems.toItemSearchResults
        } catch {
            router.display(element: .displayErrorBanner(error))
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
            showConfirmation = true
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
                try await itemRepository.updateItem(oldItem: selectedItem.item,
                                                    newItemContent: selectedItem.updateTotp(uri: totpUri).protobuf,
                                                    shareId: selectedItem.shareId)
                copyTotpToken(totpUri)
                shouldDismiss = true
            } catch {
                router.display(element: .displayErrorBanner(error))
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
            .sink { [weak self] search in
                guard let self else {
                    return
                }
                results = search.isEmpty ? searchableItems.toItemSearchResults : searchableItems
                    .result(for: search)
            }
            .store(in: &cancellables)
    }

    private var cleanedQuery: AnyPublisher<String, Never> {
        $query
            .dropFirst()
            .debounce(for: 0.4, scheduler: RunLoop.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .eraseToAnyPublisher()
    }
}
