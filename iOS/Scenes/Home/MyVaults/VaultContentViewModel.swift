//
// VaultContentViewModel.swift
// Proton Pass - Created on 21/07/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import Core
import CryptoKit
import SwiftUI

enum VaultContentViewModelError: Error {
    case itemNotFound(shareId: String, itemId: String)
    case noSelectedVault
}

extension VaultContentViewModel {
    enum State {
        case loading
        case loaded
        case error(Error)

        var isLoaded: Bool {
            switch self {
            case .loaded:
                return true
            default:
                return false
            }
        }
    }
}

final class VaultContentViewModel: BaseViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    @Published private(set) var state = State.loading
    @Published private(set) var items = [ItemListUiModel]()

    private let vaultSelection: VaultSelection
    private let actor: VaultContentViewModelActor

    var selectedVault: VaultProtocol? { vaultSelection.selectedVault }
    var vaults: [VaultProtocol] { vaultSelection.vaults }

    var onToggleSidebar: (() -> Void)?
    var onSearch: (() -> Void)?
    var onCreateItem: (() -> Void)?
    var onCreateVault: (() -> Void)?
    var onShowItemDetail: ((ItemContent) -> Void)?
    var onTrashedItem: ((ItemContentType) -> Void)?

    init(vaultSelection: VaultSelection,
         itemRepository: ItemRepositoryProtocol,
         symmetricKey: SymmetricKey) {
        self.vaultSelection = vaultSelection
        self.actor = .init(vaultSelection: vaultSelection,
                           itemRepository: itemRepository,
                           symmetricKey: symmetricKey)
        super.init()

        vaultSelection.objectWillChange
            .sink { [unowned self] _ in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

extension VaultContentViewModel {
    func fetchItems(forceRefresh: Bool) {
        Task { @MainActor in
            if case .error = state {
                state = .loading
            }

            do {
                items = try await actor.getItems(forceRefresh: forceRefresh)
                state = .loaded
            } catch {
                state = .error(error)
            }
        }
    }

    func selectItem(_ item: ItemListUiModel) {
        Task { @MainActor in
            do {
                let itemContent = try await actor.getDecryptedItemContent(item)
                onShowItemDetail?(itemContent)
            } catch {
                self.error = error
            }
        }
    }

    func trashItem(_ item: ItemListUiModel) {
        Task { @MainActor in
            isLoading = true
            do {
                try await actor.trashItem(item)
                fetchItems(forceRefresh: false)
                onTrashedItem?(item.type)
                isLoading = false
            } catch {
                isLoading = false
                self.error = error
            }
        }
    }
}

// MARK: - Actor
private actor VaultContentViewModelActor {
    private let vaultSelection: VaultSelection
    private let itemRepository: ItemRepositoryProtocol
    private let symmetricKey: SymmetricKey

    init(vaultSelection: VaultSelection,
         itemRepository: ItemRepositoryProtocol,
         symmetricKey: SymmetricKey) {
        self.vaultSelection = vaultSelection
        self.itemRepository = itemRepository
        self.symmetricKey = symmetricKey
    }

    func getItems(forceRefresh: Bool) async throws -> [ItemListUiModel] {
        guard let shareId = vaultSelection.selectedVault?.shareId else {
            throw VaultContentViewModelError.noSelectedVault
        }
        let encryptedItems = try await itemRepository.getItems(forceRefresh: forceRefresh,
                                                               shareId: shareId,
                                                               state: .active)
        return try await encryptedItems.parallelMap { try await $0.toItemListUiModel(self.symmetricKey) }
    }

    func getDecryptedItemContent(_ item: ItemListUiModel) async throws -> ItemContent {
        let encryptedItem = try await getItem(shareId: item.shareId, itemId: item.itemId)
        return try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
    }

    func trashItem(_ item: ItemListUiModel) async throws {
        let itemToBeTrashed = try await getItem(shareId: item.shareId, itemId: item.itemId)
        try await itemRepository.trashItems([itemToBeTrashed])
    }

    private func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem {
        guard let item = try await itemRepository.getItem(shareId: shareId,
                                                          itemId: itemId) else {
            throw VaultContentViewModelError.itemNotFound(shareId: shareId, itemId: itemId)
        }
        return item
    }
}
