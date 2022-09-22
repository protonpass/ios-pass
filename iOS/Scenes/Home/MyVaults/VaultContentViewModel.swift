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
import UIComponents
import UIKit

final class VaultContentViewModel: BaseViewModel, DeinitPrintable, ObservableObject {
    deinit { print(deinitMessage) }

    var selectedVault: VaultProtocol? { vaultSelection.selectedVault }
    var vaults: [VaultProtocol] { vaultSelection.vaults }

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

    @Published private(set) var state = State.idle
    @Published private(set) var items = [ItemListUiModel]()

    private let vaultSelection: VaultSelection
    private let itemRepository: ItemRepositoryProtocol
    private let symmetricKey: SymmetricKey

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
        self.itemRepository = itemRepository
        self.symmetricKey = symmetricKey
        super.init()

        vaultSelection.objectWillChange
            .sink { [unowned self] _ in
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    func update(selectedVault: VaultProtocol?) {
        vaultSelection.update(selectedVault: selectedVault)
    }

    func fetchItems(forceRefresh: Bool = false) {
        guard let shareId = selectedVault?.shareId else { return }
        Task { @MainActor in
            do {
                // Only show loading indicator on first load
                switch state {
                case .error, .idle:
                    state = .loading
                default:
                    break
                }

                let encryptedItems = try await itemRepository.getItems(forceRefresh: forceRefresh,
                                                                       shareId: shareId,
                                                                       state: .active)
                items = try await encryptedItems.parallelMap { try await $0.toItemListUiModel(self.symmetricKey) }
                state = .loaded
            } catch {
                state = .error(error)
            }
        }
    }

    func selectItem(_ item: ItemListUiModel) {
        Task { @MainActor in
            do {
                guard let item = try await itemRepository.getItem(shareId: item.shareId,
                                                                  itemId: item.itemId) else {
                    return
                }
                let itemContent = try item.getDecryptedItemContent(symmetricKey: symmetricKey)
                onShowItemDetail?(itemContent)
            } catch {
                self.error = error
            }
        }
    }

    func trashItem(_ item: ItemListUiModel) {
        Task { @MainActor in
            do {
                guard let itemToBeTrashed =
                        try await itemRepository.getItem(shareId: item.shareId,
                                                         itemId: item.itemId) else { return }
                isLoading = true
                try await itemRepository.trashItems([itemToBeTrashed])
                fetchItems(forceRefresh: false)
                isLoading = false
                onTrashedItem?(item.type)
            } catch {
                self.isLoading = false
                self.error = error
            }
        }
    }
}

// MARK: - Actions
extension VaultContentViewModel {
    func toggleSidebar() { onToggleSidebar?() }

    func search() { onSearch?() }

    func createItem() { onCreateItem?() }

    func createVault() { onCreateVault?() }
}
