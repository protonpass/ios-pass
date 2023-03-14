//
// ItemsTabViewModel.swift
// Proton Pass - Created on 07/03/2023.
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

protocol ItemsTabViewModelDelegate: AnyObject {
    func itemsTabViewModelWantsToShowSpinner()
    func itemsTabViewModelWantsToHideSpinner()
    func itemsTabViewModelWantsToCreateNewItem(shareId: String)
    func itemsTabViewModelWantsToSearch()
    func itemsTabViewModelWantsToPresentVaultList(vaultsManager: VaultsManager)
    func itemsTabViewModelWantsToPresentSortTypeList(selectedSortType: SortType,
                                                     delegate: SortTypeListViewModelDelegate)
    func itemsTabViewModelWantsViewDetail(of itemContent: ItemContent)
    func itemsTabViewModelDidTrash(item: ItemUiModel)
    func itemsTabViewModelDidEncounter(error: Error)
}

final class ItemsTabViewModel: ObservableObject, PullToRefreshable, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var selectedSortType = SortType.mostRecent

    let itemRepository: ItemRepositoryProtocol
    let logger: Logger
    let preferences: Preferences
    let vaultsManager: VaultsManager

    weak var delegate: ItemsTabViewModelDelegate?

    private var cancellables = Set<AnyCancellable>()

    /// `PullToRefreshable` conformance
    var pullToRefreshContinuation: CheckedContinuation<Void, Never>?
    let syncEventLoop: SyncEventLoop

    init(itemRepository: ItemRepositoryProtocol,
         logManager: LogManager,
         preferences: Preferences,
         syncEventLoop: SyncEventLoop,
         vaultsManager: VaultsManager) {
        self.itemRepository = itemRepository
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
        self.preferences = preferences
        self.syncEventLoop = syncEventLoop
        self.vaultsManager = vaultsManager
        self.finalizeInitialization()
    }
}

// MARK: - Private APIs
private extension ItemsTabViewModel {
    func finalizeInitialization() {
        vaultsManager.attach(to: self, storeIn: &cancellables)
    }
}

// MARK: - Public APIs
extension ItemsTabViewModel {
    func createNewItem() {
        switch vaultsManager.vaultSelection {
        case .all:
            // Handle this later
            break
        case .precise(let selectedVault):
            delegate?.itemsTabViewModelWantsToCreateNewItem(shareId: selectedVault.shareId)
        }
    }

    func search() {
        delegate?.itemsTabViewModelWantsToSearch()
    }

    func presentVaultList() {
        switch vaultsManager.state {
        case .loaded:
            delegate?.itemsTabViewModelWantsToPresentVaultList(vaultsManager: vaultsManager)
        default:
            logger.error("Can not present vault list. Vaults are not loaded.")
        }
    }

    func presentSortTypeList() {
        delegate?.itemsTabViewModelWantsToPresentSortTypeList(selectedSortType: selectedSortType,
                                                              delegate: self)
    }

    func viewDetail(of item: ItemUiModel) {
        Task { @MainActor in
            do {
                if let itemContent =
                    try await itemRepository.getDecryptedItemContent(shareId: item.shareId,
                                                                     itemId: item.itemId) {
                    delegate?.itemsTabViewModelWantsViewDetail(of: itemContent)
                }
            } catch {
                delegate?.itemsTabViewModelDidEncounter(error: error)
            }
        }
    }

    func trash(item: ItemUiModel) {
        Task { @MainActor in
            defer { delegate?.itemsTabViewModelWantsToHideSpinner() }
            do {
                delegate?.itemsTabViewModelWantsToShowSpinner()
                if let encryptedItem = try await itemRepository.getItem(shareId: item.shareId,
                                                                        itemId: item.itemId) {
                    try await itemRepository.trashItems([encryptedItem])
                    delegate?.itemsTabViewModelDidTrash(item: item)
                } else {
                    let error = PPError.itemNotFound(shareID: item.shareId, itemID: item.itemId)
                    delegate?.itemsTabViewModelDidEncounter(error: error)
                }
            } catch {
                delegate?.itemsTabViewModelDidEncounter(error: error)
            }
        }
    }
}

// MARK: - SortTypeListViewModelDelegate
extension ItemsTabViewModel: SortTypeListViewModelDelegate {
    func sortTypeListViewDidSelect(_ sortType: SortType) {
        selectedSortType = sortType
    }
}

// MARK: - SyncEventLoopPullToRefreshDelegate
extension ItemsTabViewModel: SyncEventLoopPullToRefreshDelegate {
    func pullToRefreshShouldStopRefreshing() {
        stopRefreshing()
    }
}
