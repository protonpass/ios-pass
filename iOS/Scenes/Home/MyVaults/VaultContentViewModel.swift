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
        case idle
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

    @Published private(set) var state = State.idle
    @Published private(set) var items = [ItemListUiModel]()

    private let vaultSelection: VaultSelection
    private var actor: VaultContentViewModelActor!

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
        super.init()
        self.actor = .init(viewModel: self,
                           vaultSelection: vaultSelection,
                           itemRepository: itemRepository,
                           symmetricKey: symmetricKey)

        vaultSelection.objectWillChange
            .sink { [unowned self] _ in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func update(selectedVault: VaultProtocol?) {
        vaultSelection.update(selectedVault: selectedVault)
    }

    func update(items: [ItemListUiModel]) {
        self.items = items
    }

    func update(state: State) {
        self.state = state
    }

    func update(isLoading: Bool) {
        self.isLoading = isLoading
    }

    func handle(error: Error) {
        self.error = error
    }
}

extension VaultContentViewModel {
    func fetchItems(forceRefresh: Bool) {
        switch state {
        case .error, .idle:
            state = .loading
        default:
            break
        }
        Task.detached {
            await self.actor.getItems(forceRefresh: forceRefresh)
        }
    }

    func selectItem(_ item: ItemListUiModel) {
        Task.detached {
            await self.actor.getDecryptedItemContent(shareId: item.shareId,
                                                     itemId: item.itemId)
        }
    }

    func trashItem(_ item: ItemListUiModel) {
        Task.detached {
            await self.actor.trashItem(item)
        }
    }
}

// MARK: - Actor
private actor VaultContentViewModelActor {
    unowned let viewModel: VaultContentViewModel
    private let vaultSelection: VaultSelection
    private let itemRepository: ItemRepositoryProtocol
    private let symmetricKey: SymmetricKey

    init(viewModel: VaultContentViewModel,
         vaultSelection: VaultSelection,
         itemRepository: ItemRepositoryProtocol,
         symmetricKey: SymmetricKey) {
        self.viewModel = viewModel
        self.vaultSelection = vaultSelection
        self.itemRepository = itemRepository
        self.symmetricKey = symmetricKey
    }

    nonisolated func getItems(forceRefresh: Bool) async {
        guard let shareId = vaultSelection.selectedVault?.shareId else {
            await updateState(state: .error(VaultContentViewModelError.noSelectedVault))
            return
        }
        do {
            let encryptedItems = try await itemRepository.getItems(forceRefresh: forceRefresh,
                                                                   shareId: shareId,
                                                                   state: .active)
            let items = try await encryptedItems.parallelMap { try await $0.toItemListUiModel(self.symmetricKey) }
            Task { @MainActor in
                viewModel.update(items: items)
                viewModel.update(state: .loaded)
            }
        } catch {
            await updateState(state: .error(error))
        }
    }

    func getDecryptedItemContent(shareId: String, itemId: String) async {
        do {
            let encryptedItem = try await getItem(shareId: shareId, itemId: itemId)
            let decryptedItem = try encryptedItem.getDecryptedItemContent(symmetricKey: symmetricKey)
            Task { @MainActor in
                viewModel.onShowItemDetail?(decryptedItem)
            }
        } catch {
            await updateState(state: .error(error))
        }
    }

    func trashItem(_ item: ItemListUiModel) async {
        do {
            await update(isLoading: true)
            let itemToBeTrashed = try await getItem(shareId: item.shareId, itemId: item.itemId)
            try await itemRepository.trashItems([itemToBeTrashed])
            await getItems(forceRefresh: false)
            await update(isLoading: false)
            Task { @MainActor in
                viewModel.onTrashedItem?(item.type)
            }
        } catch {
            await update(isLoading: false)
            await handleError(error)
        }
    }

    private func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem {
        guard let item = try await itemRepository.getItem(shareId: shareId,
                                                          itemId: itemId) else {
            throw VaultContentViewModelError.itemNotFound(shareId: shareId, itemId: itemId)
        }
        return item
    }

    @MainActor
    private func updateState(state: VaultContentViewModel.State) {
        viewModel.update(state: state)
    }

    @MainActor
    private func update(isLoading: Bool) {
        viewModel.update(isLoading: isLoading)
    }

    @MainActor
    private func handleError(_ error: Error) {
        viewModel.handle(error: error)
    }
}
