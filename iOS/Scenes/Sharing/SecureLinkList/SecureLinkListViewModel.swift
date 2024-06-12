//
//
// SecureLinkListViewModel.swift
// Proton Pass - Created on 11/06/2024.
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

import Combine
import Entities
import Factory
import Foundation
import SwiftUI

enum SecureLinkListDisplay {
    case cell
    case row
}

@MainActor
final class SecureLinkListViewModel: ObservableObject, Sendable {
    @Published var display: SecureLinkListDisplay = .cell
    @Published var secureLinks: [SecureLinkListUIModel]?
    @Published var loading = false
    @Published var searchText = ""

    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let deleteSecureLink = resolve(\UseCasesContainer.deleteSecureLink)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let getSecureLinkList = resolve(\UseCasesContainer.getSecureLinkList)
    private var links: [SecureLink]?
    private var items = [SecureLinkListUIModel]()

    private var cancellables = Set<AnyCancellable>()

    var isPhone: Bool {
        UIDevice.current.userInterfaceIdiom == .phone
    }

    init(links: [SecureLink]?) {
        self.links = links
        setUp()
    }

    func displayToggle() {
        display = display == .cell ? .row : .cell
    }

    func goToDetail(link: SecureLinkListUIModel) {
        router.present(for: .secureLinkDetail(link))
    }

    func deleteLink(link: SecureLinkListUIModel) {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            loading = true
            do {
                try await deleteSecureLink(linkId: link.secureLink.linkID)
                removeLocalLink(item: link)
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func load() async {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            loading = true
            do {
                try await fetchLinksContent()

//                let itemsIds = links.map { (sharedId: $0.shareID, itemId: $0.itemID) }
//                let itemContents = try await itemRepository.getAllItemsContent(items: itemsIds)
//                items = links.compactMap { link in
//                    guard let content = itemContents
//                        .first(where: { $0.shareId == link.shareID && $0.item.itemID == link.itemID }) else {
//                        return nil
//                    }
//                    return SecureLinkListUIModel(secureLink: link, itemContent: content)
//                }
//                if secureLinks != items {
//                    secureLinks = items
//                }
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func refresh() async {
        Task { [weak self] in
            guard let self else { return }
//            defer { loading = false }
//            loading = true
            do {
                links = try await getSecureLinkList()

                if let links {
                    try await updateLocalData(links: links)
                }

//                let itemsIds = links.map { (sharedId: $0.shareID, itemId: $0.itemID) }
//                let itemContents = try await itemRepository.getAllItemsContent(items: itemsIds)
//                items = links.compactMap { link in
//                    guard let content = itemContents
//                        .first(where: { $0.shareId == link.shareID && $0.item.itemID == link.itemID }) else {
//                        return nil
//                    }
//                    return SecureLinkListUIModel(secureLink: link, itemContent: content)
//                }
//                if secureLinks != items {
//                    secureLinks = items
//                }
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

private extension SecureLinkListViewModel {
    func setUp() {
        $searchText
            .debounce(for: 0.3, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] search in
                guard let self else { return }

                if search.isEmpty {
                    secureLinks = items
                } else {
                    secureLinks = items.filter { item in
                        item.itemContent.title.lowercased().contains(search.lowercased)
                    }
                }
            }
            .store(in: &cancellables)
    }

    func fetchLinksContent() async throws {
        if links == nil {
            links = try await getSecureLinkList()
        }
        guard let links else {
            return
        }
        try await updateLocalData(links: links)
    }

    func updateLocalData(links: [SecureLink]) async throws {
        let itemsIds = links.map { (sharedId: $0.shareID, itemId: $0.itemID) }
        let itemContents = try await itemRepository.getAllItemsContent(items: itemsIds)
        items = links.compactMap { link in
            guard let content = itemContents
                .first(where: { $0.shareId == link.shareID && $0.item.itemID == link.itemID }) else {
                return nil
            }
            return SecureLinkListUIModel(secureLink: link, itemContent: content)
        }
        if secureLinks != items {
            secureLinks = items
        }
    }

    func removeLocalLink(item: SecureLinkListUIModel) {
        links?.removeAll { $0.linkID == item.secureLink.linkID }
        items
            .removeAll {
                $0.secureLink.linkID == item.secureLink.linkID
            }
        secureLinks?
            .removeAll {
                $0.secureLink.linkID == item.secureLink.linkID
            }
    }
}
