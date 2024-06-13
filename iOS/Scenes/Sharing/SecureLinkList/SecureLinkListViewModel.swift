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
import Macro
import SwiftUI

enum SecureLinkListDisplay: Int {
    case cell = 0
    case row = 1
}

@MainActor
final class SecureLinkListViewModel: ObservableObject, Sendable {
    @AppStorage("display") var display: SecureLinkListDisplay = .cell {
        didSet {
            objectWillChange.send()
        }
    }

    @Published var secureLinks: [SecureLinkListUIModel]?
    @Published var loading = false
    @Published var searchText = ""

    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let deleteSecureLink = resolve(\UseCasesContainer.deleteSecureLink)
    private let recreateSecureLink = resolve(\UseCasesContainer.recreateSecureLink)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
//    private let getSecureLinkList = resolve(\UseCasesContainer.getSecureLinkList)
    private let secureLinkManager = resolve(\ServiceContainer.secureLinkManager)
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
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func load() async {
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            if links == nil || (links?.isEmpty ?? true) {
                loading = true
            }
            do {
                try await fetchLinksContent()
            } catch {
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func refresh() async {
        try? await secureLinkManager.updateSecureLinks()

//        Task { [weak self] in
//            guard let self else { return }
//            do {
//                links = try await secureLinkManager.updateSecureLinks() // try await getSecureLinkList()
//
//                if let links {
//                    try await updateLocalData(links: links)
//                }
//            } catch {
//                router.display(element: .displayErrorBanner(error))
//            }
//        }
    }

    func copyLink(_ item: SecureLinkListUIModel) {
        router.action(.copyToClipboard(text: item.url, message: #localized("Secure link copied")))
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

        secureLinkManager.currentSecureLinks
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLinks in
                guard let self, let newLinks else { return }
                links = newLinks
                guard let links else { return }
                Task { [weak self] in
                    guard let self else { return }
                    do {
                        try await updateLocalData(links: links)
                    } catch {
                        router.display(element: .displayErrorBanner(error))
                    }
                }
            }
            .store(in: &cancellables)
    }

    func fetchLinksContent() async throws {
        try await secureLinkManager.updateSecureLinks()
//        if links == nil {
//        secureLinkManager.loadLinks()
//        }

//        if links == nil {
//            links = try await secureLinkManager.updateSecureLinks() // getSecureLinkList()
//        }
//        guard let links else {
//            return
//        }
//        try await updateLocalData(links: links)
    }

    func updateLocalData(links: [SecureLink]) async throws {
        let itemsIds = links.map { (sharedId: $0.shareID, itemId: $0.itemID) }
        let itemContents = try await itemRepository.getAllItemsContent(items: itemsIds)

        items = try await links.asyncCompactMap { link -> SecureLinkListUIModel? in
            guard let content = itemContents
                .first(where: { $0.shareId == link.shareID && $0.item.itemID == link.itemID }) else {
                return nil
            }
            let url = try await recreateSecureLink(for: link)
            return SecureLinkListUIModel(secureLink: link, itemContent: content, url: url)
        }
        if secureLinks != items {
            secureLinks = items
        }
    }
}
