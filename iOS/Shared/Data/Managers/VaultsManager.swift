//
// VaultsManager.swift
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
import CryptoKit
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreLogin

enum VaultManagerState {
    case loading
    case loaded(vaults: [VaultContentUiModel], trashedItems: [ItemUiModel])
    case error(Error)
}

final class VaultsManager: ObservableObject, DeinitPrintable, VaultsManagerProtocol {
    deinit { print(deinitMessage) }

    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let shareRepository = resolve(\SharedRepositoryContainer.shareRepository)
    private let vaultSyncEventStream = resolve(\SharedDataStreamContainer.vaultSyncEventStream)
    private let logger = resolve(\SharedToolingContainer.logger)
    private var loginMethod = resolve(\SharedDataContainer.loginMethod)
    private var symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)
    private var isRefreshing = false

    // Use cases
    private let indexAllLoginItems = resolve(\SharedUseCasesContainer.indexAllLoginItems)

    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var state = VaultManagerState.loading
    @Published private(set) var vaultSelection = VaultSelection.all
    @Published private(set) var filterOption = ItemTypeFilterOption.all
    @Published private(set) var itemCount = ItemCount.zero

    let currentVaults: CurrentValueSubject<[Vault], Never> = .init([])

    init() {
        setUp()
    }

    var hasOnlyOneOwnedVault: Bool {
        getAllVaults().numberOfOwnedVault <= 1
    }

    @MainActor
    func reset() {
        state = .loading
        vaultSelection = .all
        filterOption = .all
        itemCount = .zero
        currentVaults.send([])
    }
}

// MARK: - Private APIs

private extension VaultsManager {
    func setUp() {
        $state
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                updateItemCount()
            }
            .store(in: &cancellables)

        $vaultSelection
            .receive(on: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                guard let self else { return }
                // Reset back to filter "all" when switching vaults
                filterOption = .all
                updateItemCount()
            }
            .store(in: &cancellables)
    }

    func updateItemCount() {
        guard case let .loaded(vaults, trashedItems) = state else { return }
        let items: [ItemTypeIdentifiable]
        switch vaultSelection {
        case .all:
            items = vaults.map(\.items).reduce(into: []) { $0 += $1 }
        case let .precise(selectedVault):
            items = vaults
                .filter { $0.vault.shareId == selectedVault.shareId }
                .map(\.items)
                .reduce(into: []) { $0 += $1 }
        case .trash:
            items = trashedItems
        }
        itemCount = .init(items: items)
    }

    @MainActor
    func createDefaultVault() async throws {
        logger.trace("Creating default vault for user")
        let vault = VaultProtobuf(name: #localized("Personal"),
                                  description: #localized("Personal"),
                                  color: .color1,
                                  icon: .icon1)
        try await shareRepository.createVault(vault)
        logger.info("Created default vault for user")
    }

    @MainActor
    func loadContents(for vaults: [Vault]) async throws {
        let symmetricKey = try symmetricKeyProvider.getSymmetricKey()
        let allItems = try await itemRepository.getAllItems()
        let allItemUiModels = try allItems.map { try $0.toItemUiModel(symmetricKey) }
        currentVaults.send(vaults)
        var vaultContentUiModels = vaults.map { vault in
            let items = allItemUiModels
                .filter { $0.shareId == vault.shareId }
                .filter { $0.state == .active }
            return VaultContentUiModel(vault: vault, items: items)
        }
        vaultContentUiModels.sortAlphabetically()

        let trashedItems = allItemUiModels.filter { $0.state == .trashed }

        // Reset to `all` when last selected vault is deleted
        if case let .precise(selectedVault) = vaultSelection {
            if !vaults.contains(where: { $0 == selectedVault }) {
                vaultSelection = .all
            }
        }

        state = .loaded(vaults: vaultContentUiModels, trashedItems: trashedItems)

        if await loginMethod.isManualLogIn() {
            try await indexAllLoginItems(ignorePreferences: false)
        } else {
            Task.detached(priority: .background) { [weak self] in
                guard let self else { return }
                try await indexAllLoginItems(ignorePreferences: false)
            }
        }
    }
}

// MARK: - Public APIs

extension VaultsManager {
    func refresh() {
        guard !isRefreshing else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await asyncRefresh()
        }
    }

    @MainActor
    func asyncRefresh() async throws {
        guard !isRefreshing else { return }
        defer { isRefreshing = false }
        do {
            // No need to show loading indicator once items are loaded beforehand.
            var cryptoErrorOccured = false
            switch state {
            case .loaded:
                break
            case let .error(error):
                cryptoErrorOccured = error is CryptoKitError
                state = .loading
            default:
                state = .loading
            }

            if await loginMethod.isManualLogIn() {
                logger.info("Manual login, doing full sync")
                try await fullSync()
                await loginMethod.setLogInFlow(newState: false)
                logger.info("Manual login, done full sync")
            } else if cryptoErrorOccured {
                logger.info("Crypto error occured. Doing full sync")
                try await fullSync()
                logger.info("Crypto error occured. Done full sync")
            } else {
                logger.info("Not manual login, getting local shares & items")
                let vaults = try await shareRepository.getVaults()
                try await loadContents(for: vaults)
                logger.info("Not manual login, done getting local shares & items")
            }
        } catch {
            state = .error(error)
        }
    }

    // Delete everything and download again
    func fullSync() async throws {
        vaultSyncEventStream.send(.started)

        // 1. Delete all local items & shares
        try await itemRepository.deleteAllItemsLocally()
        try await shareRepository.deleteAllSharesLocally()

        // 2. Get all remote shares and their items
        let remoteShares = try await shareRepository.getRemoteShares(eventStream: vaultSyncEventStream)
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for share in remoteShares {
                taskGroup.addTask { [weak self] in
                    guard let self else { return }
                    try await shareRepository.upsertShares([share],
                                                           eventStream: vaultSyncEventStream)
                    try await itemRepository.refreshItems(shareId: share.shareID,
                                                          eventStream: vaultSyncEventStream)
                }
            }
        }

        // 3. Create default vault if no vaults
        if remoteShares.isEmpty {
            try await createDefaultVault()
        }

        // 4. Load vaults and their contents
        var vaults = try await shareRepository.getVaults()

        // 5. Check if in "forgot password" scenario. Create a new default vault if applicable
        let hasRemoteVaults = remoteShares.contains(where: { $0.shareType == .vault })
        // We see that there are remote vaults but we can't decrypt any of them
        // => "forgot password" happened
        if hasRemoteVaults, vaults.isEmpty {
            try await createDefaultVault()
            vaults = try await shareRepository.getVaults()
        }

        try await loadContents(for: vaults)

        vaultSyncEventStream.send(.done)
    }

    func select(_ selection: VaultSelection) {
        vaultSelection = selection
    }

    func isSelected(_ selection: VaultSelection) -> Bool {
        vaultSelection == selection
    }

    func getItems(for vault: Vault) -> [ItemUiModel] {
        guard case let .loaded(vaults, _) = state else { return [] }

        return vaults.first { $0.vault.id == vault.id }?.items ?? []
    }

    func getItemCount(for vault: Vault) -> Int {
        getItems(for: vault).count
    }

    func getItemCount(for selection: VaultSelection) -> Int {
        guard case let .loaded(vaults, trashedItems) = state else { return 0 }
        switch selection {
        case .all:
            return vaults.map(\.items.count).reduce(into: 0) { $0 += $1 }
        case let .precise(vault):
            return vaults.first { $0.vault == vault }?.items.count ?? 0
        case .trash:
            return trashedItems.count
        }
    }

    func getAllVaultContents() -> [VaultContentUiModel] {
        guard case let .loaded(vaults, _) = state else { return [] }
        return vaults
    }

    func getAllEditableVaultContents() -> [VaultContentUiModel] {
        getAllVaultContents().filter(\.vault.canEdit)
    }

    func getAllVaults() -> [Vault] {
        guard case let .loaded(vaults, _) = state else { return [] }
        return vaults.map(\.vault)
    }

    func vaultHasTrashedItems(_ vault: Vault) -> Bool {
        guard case let .loaded(_, trashedItems) = state else { return false }
        return trashedItems.contains { $0.shareId == vault.shareId }
    }

    func delete(vault: Vault) async throws {
        let shareId = vault.shareId
        logger.trace("Deleting vault \(shareId)")
        try await shareRepository.deleteVault(shareId: shareId)
        switch state {
        case let .loaded(vaults, trashedItems):
            logger.trace("Deleting local active items of vault \(shareId)")
            if let deletedVault = vaults.first(where: { $0.vault.shareId == shareId }) {
                let itemIds = deletedVault.items.map(\.itemId)
                try await itemRepository.deleteItemsLocally(itemIds: itemIds, shareId: shareId)
            }

            logger.trace("Deleting local trashed items of vault \(shareId)")
            let trashedItemsToBeRemoved = trashedItems.filter { $0.shareId == shareId }
            try await itemRepository.deleteItemsLocally(itemIds: trashedItemsToBeRemoved.map(\.itemId),
                                                        shareId: shareId)

        default:
            break
        }
        // Delete local items of the vault
        logger.info("Deleted vault \(shareId)")
    }

    func restoreAllTrashedItems() async throws {
        logger.trace("Restoring all trashed items")
        let trashedItems = try await itemRepository.getItems(state: .trashed)
        try await itemRepository.untrashItems(trashedItems)
        logger.info("Restored all trashed items")
    }

    func permanentlyDeleteAllTrashedItems() async throws {
        logger.trace("Permanently deleting all trashed items")
        let trashedItems = try await itemRepository.getItems(state: .trashed)
        try await itemRepository.deleteItems(trashedItems, skipTrash: false)
        logger.info("Permanently deleted all trashed items")
    }

    func getOldestOwnedVault() -> Vault? {
        guard case let .loaded(uiModels, _) = state else { return nil }
        let vaults = uiModels.map(\.vault)
        return vaults.oldestOwned
    }

    func getFilteredItems() -> [ItemUiModel] {
        guard case let .loaded(vaults, trashedItems) = state else { return [] }
        let items: [ItemUiModel]
        switch vaultSelection {
        case .all:
            items = vaults.map(\.items).reduce(into: []) { $0 += $1 }
        case let .precise(selectedVault):
            items = vaults
                .filter { $0.vault.shareId == selectedVault.shareId }
                .map(\.items)
                .reduce(into: []) { $0 += $1 }
        case .trash:
            items = trashedItems
        }

        switch filterOption {
        case .all:
            return items
        case let .precise(type):
            return items.filter { $0.type == type }
        }
    }

    func updateItemTypeFilterOption(_ filterOption: ItemTypeFilterOption) {
        self.filterOption = filterOption
    }
}

// MARK: - LimitationCounterProtocol

extension VaultsManager: LimitationCounterProtocol {
    func getAliasCount() -> Int {
        switch state {
        case let .loaded(vaults, trash):
            let activeAliases = vaults.flatMap(\.items).filter(\.isAlias)
            let trashedAliases = trash.filter(\.isAlias)
            return activeAliases.count + trashedAliases.count
        default:
            return 0
        }
    }

    func getTOTPCount() -> Int {
        guard case let .loaded(vaults, trashedItems) = state else { return 0 }
        let activeItemsWithTotpUri = vaults.flatMap(\.items).filter(\.hasTotpUri).count
        let trashedItemsWithTotpUri = trashedItems.filter(\.hasTotpUri).count
        return activeItemsWithTotpUri + trashedItemsWithTotpUri
    }

    func getVaultCount() -> Int {
        switch state {
        case let .loaded(vaults, _):
            vaults.count
        default:
            0
        }
    }
}

extension VaultManagerState: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            true
        case let (.loaded(lhsVaults, lhsTrashedItems), .loaded(rhsVaults, rhsTrashedItems)):
            lhsVaults.hashValue == rhsVaults.hashValue &&
                lhsTrashedItems.hashValue == rhsTrashedItems.hashValue
        case let (.error(lhsError), .error(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        default:
            false
        }
    }
}
