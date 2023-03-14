//
// TrashViewModel.swift
// Proton Pass - Created on 09/09/2022.
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
import ProtonCore_Login
import SwiftUI

protocol TrashViewModelDelegate: AnyObject {
    func trashViewModelWantsToToggleSidebar()
    func trashViewModelWantsToShowLoadingHud()
    func trashViewModelWantsToHideLoadingHud()
    func trashViewModelWantsShowItemDetail(_ item: ItemContent)
    func trashViewModelDidRestoreItem(_ item: ItemIdentifiable, type: ItemContentType)
    func trashViewModelDidRestoreAllItems(count: Int)
    func trashViewModelDidDeleteItem(_ type: ItemContentType)
    func trashViewModelDidEmptyTrash()
    func trashViewModelDidFail(_ error: Error)
}

final class TrashViewModel: DeinitPrintable, PullToRefreshable, ObservableObject {
    @Published private(set) var state = State.loading
    @Published private(set) var items = [ItemUiModel]()

    var itemsDictionary = [String: [ItemUiModel]]()

    private let symmetricKey: SymmetricKey
    private let shareRepository: ShareRepositoryProtocol
    private let itemRepository: ItemRepositoryProtocol
    private let logger: Logger

    /// `PullToRefreshable` conformance
    var pullToRefreshContinuation: CheckedContinuation<Void, Never>?
    let syncEventLoop: SyncEventLoop

    weak var delegate: TrashViewModelDelegate?

    enum State {
        case loading
        case loaded
        case error(Error)
    }

    var isEmpty: Bool {
        switch state {
        case .loaded:
            return itemsDictionary.isEmpty
        default:
            return true
        }
    }

    init(symmetricKey: SymmetricKey,
         shareRepository: ShareRepositoryProtocol,
         itemRepository: ItemRepositoryProtocol,
         syncEventLoop: SyncEventLoop,
         logManager: LogManager) {
        self.symmetricKey = symmetricKey
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.syncEventLoop = syncEventLoop
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
        fetchAllTrashedItems()
    }

    func fetchAllTrashedItems() {
        Task { @MainActor in
            do {
                logger.trace("Loading all trashed items")
                if case .error = state {
                    state = .loading
                }

                items = try await getTrashedItemsTask().value
                state = .loaded
                logger.info("Loaded \(items.count) trashed items")
            } catch {
                logger.error(error)
                state = .error(error)
            }
        }
    }
}

// MARK: - Actions
extension TrashViewModel {
    func toggleSidebar() {
        delegate?.trashViewModelWantsToToggleSidebar()
    }

    func restoreAllItems() {
        Task { @MainActor in
            defer { delegate?.trashViewModelWantsToHideLoadingHud() }
            do {
                logger.trace("Restoring all trashed items")
                delegate?.trashViewModelWantsToShowLoadingHud()
                let count = try await restoreAllTask().value
                items.removeAll()
                delegate?.trashViewModelDidRestoreAllItems(count: count)
                logger.info("Restored all trashed items")
            } catch {
                logger.error(error)
                delegate?.trashViewModelDidFail(error)
            }
        }
    }

    func emptyTrash() {
        Task { @MainActor in
            defer { delegate?.trashViewModelWantsToHideLoadingHud() }
            do {
                logger.trace("Emptying trash")
                delegate?.trashViewModelWantsToShowLoadingHud()
                try await deleteAllTask().value
                items.removeAll()
                delegate?.trashViewModelDidEmptyTrash()
                logger.info("Emptied trash")
            } catch {
                logger.error(error)
                delegate?.trashViewModelDidFail(error)
            }
        }
    }

    func selectItem(_ item: ItemUiModel) {
        Task { @MainActor in
            do {
                let itemContent = try await getDecryptedItemContentTask(for: item).value
                delegate?.trashViewModelWantsShowItemDetail(itemContent)
                logger.info("Want to view detail \(item.debugInformation)")
            } catch {
                logger.error(error)
                delegate?.trashViewModelDidFail(error)
            }
        }
    }

    func restore(_ item: ItemUiModel) {
        Task { @MainActor in
            defer { delegate?.trashViewModelWantsToHideLoadingHud() }
            do {
                logger.trace("Restoring \(item.debugInformation)")
                delegate?.trashViewModelWantsToShowLoadingHud()
                try await restoreItemTask(item).value
                remove(item)
                delegate?.trashViewModelDidRestoreItem(item, type: item.type)
                logger.info("Restored \(item.debugInformation)")
            } catch {
                logger.error(error)
                delegate?.trashViewModelDidFail(error)
            }
        }
    }

    func deletePermanently(_ item: ItemUiModel) {
        Task { @MainActor in
            defer { delegate?.trashViewModelWantsToHideLoadingHud() }
            do {
                logger.trace("Deleting \(item.debugInformation)")
                delegate?.trashViewModelWantsToShowLoadingHud()
                try await deleteItemTask(item).value
                remove(item)
                delegate?.trashViewModelDidDeleteItem(item.type)
                logger.info("Deleted \(item.debugInformation)")
            } catch {
                logger.error(error)
                delegate?.trashViewModelDidFail(error)
            }
        }
    }

    private func remove(_ item: ItemUiModel) {
        items.removeAll(where: { $0.itemId == item.itemId })
    }
}

// MARK: - Private supporting tasks
private extension TrashViewModel {
    func getTrashedItemsTask() -> Task<[ItemUiModel], Error> {
        Task.detached(priority: .userInitiated) {
            let items = try await self.itemRepository.getItems(state: .trashed)
            return try await items.parallelMap { try await $0.toItemUiModel(self.symmetricKey) }
        }
    }

    func restoreItemTask(_ item: ItemUiModel) -> Task<Void, Error> {
        Task.detached(priority: .userInitiated) {
            let item = try await self.getItem(item)
            try await self.itemRepository.untrashItems([item])
        }
    }

    func restoreAllTask() -> Task<Int, Error> {
        Task.detached(priority: .userInitiated) {
            let items = try await self.itemRepository.getItems(state: .trashed)
            try await self.itemRepository.untrashItems(items)
            return items.count
        }
    }

    func deleteAllTask() -> Task<Void, Error> {
        Task.detached(priority: .userInitiated) {
            let items = try await self.itemRepository.getItems(state: .trashed)
            try await self.itemRepository.deleteItems(items, skipTrash: false)
        }
    }

    func deleteItemTask(_ item: ItemUiModel) -> Task<Void, Error> {
        Task.detached(priority: .userInitiated) {
            let item = try await self.getItem(item)
            try await self.itemRepository.deleteItems([item], skipTrash: false)
        }
    }

    func getItem(_ item: ItemUiModel) async throws -> SymmetricallyEncryptedItem {
        guard let item = try await itemRepository.getItem(shareId: item.shareId,
                                                          itemId: item.itemId) else {
            throw PPError.itemNotFound(shareID: item.shareId, itemID: item.itemId)
        }
        return item
    }

    func getDecryptedItemContentTask(for item: ItemUiModel) -> Task<ItemContent, Error> {
        Task.detached(priority: .userInitiated) {
            let encryptedItem = try await self.getItem(item)
            return try encryptedItem.getDecryptedItemContent(symmetricKey: self.symmetricKey)
        }
    }
}

extension TrashViewModel: SyncEventLoopPullToRefreshDelegate {
    func pullToRefreshShouldStopRefreshing() {
        stopRefreshing()
    }
}
