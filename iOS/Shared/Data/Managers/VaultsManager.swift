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
@preconcurrency import CryptoKit
import Entities
import Factory
import Foundation
import Macro
import ProtonCoreLogin
import SwiftUI

enum VaultManagerState {
    case loading
    case loaded(vaults: [VaultContentUiModel], trashedItems: [ItemUiModel])
    case error(any Error)
}

final class VaultsManager: ObservableObject, @unchecked Sendable, DeinitPrintable, VaultsManagerProtocol {
    deinit { print(deinitMessage) }

    private let itemRepository = resolve(\SharedRepositoryContainer.itemRepository)
    private let shareRepository = resolve(\SharedRepositoryContainer.shareRepository)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let loginMethod = resolve(\SharedDataContainer.loginMethod)
    private let symmetricKeyProvider = resolve(\SharedDataContainer.symmetricKeyProvider)

    private let queue = DispatchQueue(label: "me.proton.pass.vaultsManager")
    private var safeIsRefreshing = false
    private var isRefreshing: Bool {
        get {
            queue.sync {
                safeIsRefreshing
            }
        }
        set {
            queue.sync {
                safeIsRefreshing = newValue
            }
        }
    }

    // Use cases
    private let indexAllLoginItems = resolve(\SharedUseCasesContainer.indexAllLoginItems)
    private let indexItemsForSpotlight = resolve(\SharedUseCasesContainer.indexItemsForSpotlight)
    private let deleteLocalDataBeforeFullSync = resolve(\SharedUseCasesContainer.deleteLocalDataBeforeFullSync)
    private let getSharedPreferences = resolve(\SharedUseCasesContainer.getSharedPreferences)
    private let getUserPreferences = resolve(\SharedUseCasesContainer.getUserPreferences)

    @LazyInjected(\SharedUseCasesContainer.updateUserPreferences)
    private var updateUserPreferences

    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var state = VaultManagerState.loading
    @Published private(set) var vaultSelection = VaultSelection.all
    @Published private(set) var itemCount = ItemCount.zero

    @AppStorage(Constants.filterTypeKey, store: kSharedUserDefaults)
    private(set) var filterOption = ItemTypeFilterOption.all

    @AppStorage(Constants.incompleteFullSyncUserId, store: kSharedUserDefaults)
    private(set) var incompleteFullSyncUserId: String?

    let currentVaults: CurrentValueSubject<[Vault], Never> = .init([])

    let vaultSyncEventStream = CurrentValueSubject<VaultSyncProgressEvent, Never>(.initialization)

    // The filter option after switching vaults
    private var pendingItemTypeFilterOption: ItemTypeFilterOption?

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
        itemCount = .zero
        currentVaults.send([])
        vaultSyncEventStream.value = .initialization
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
            .dropFirst()
            .sink { [weak self] _ in
                guard let self else { return }
                filterOption = pendingItemTypeFilterOption ?? .all
                pendingItemTypeFilterOption = nil
                updateItemCount()
            }
            .store(in: &cancellables)
    }

    func updateItemCount() {
        guard case let .loaded(vaults, trashedItems) = state else { return }
        let items: [any ItemTypeIdentifiable] = switch vaultSelection {
        case .all:
            vaults.flatMap(\.items)
        case let .precise(selectedVault):
            vaults
                .filter { $0.vault.shareId == selectedVault.shareId }
                .flatMap(\.items)
        case .trash:
            trashedItems
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
    func loadContents(userId: String, for vaults: [Vault]) async throws {
        let symmetricKey = try await symmetricKeyProvider.getSymmetricKey()
        let allItems = try await itemRepository.getAllItems(userId: userId)
        let allItemUiModels = try allItems.map { try $0.toItemUiModel(symmetricKey) }
        var vaultContentUiModels = vaults.map { vault in
            let items = allItemUiModels
                .filter { $0.shareId == vault.shareId }
                .filter { $0.state == .active }
            return VaultContentUiModel(vault: vault, items: items)
        }
        vaultContentUiModels.sortAlphabetically()

        let trashedItems = allItemUiModels.filter { $0.state == .trashed }

        let indexForAutoFillAndSplotlight: @Sendable () async -> Void = { [weak self] in
            guard let self else { return }
            // "Do catch" separately because we don't want an operation to fail the others
            do {
                if getSharedPreferences().quickTypeBar {
                    try await indexAllLoginItems()
                }
            } catch {
                logger.error(error)
            }

            do {
                try await indexItemsForSpotlight(getUserPreferences())
            } catch {
                logger.error(error)
            }
        }

        currentVaults.send(vaults)
        state = .loaded(vaults: vaultContentUiModels, trashedItems: trashedItems)
        if let lastSelectedShareId = getUserPreferences().lastSelectedShareId,
           let vault = vaults.first(where: { $0.shareId == lastSelectedShareId }) {
            vaultSelection = .precise(vault)
        } else {
            vaultSelection = .all
        }

        if await loginMethod.isManualLogIn() {
            await indexForAutoFillAndSplotlight()
        } else {
            Task.detached(priority: .background) {
                await indexForAutoFillAndSplotlight()
            }
        }
    }
}

// MARK: - Public APIs

extension VaultsManager {
    func refresh(userId: String) {
        guard !isRefreshing else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            try? await asyncRefresh(userId: userId)
        }
    }

    @MainActor
    func asyncRefresh(userId: String) async throws {
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
                await fullSync(userId: userId)
                await loginMethod.setLogInFlow(newState: false)
                logger.info("Manual login, done full sync")
            } else if cryptoErrorOccured {
                logger.info("Crypto error occurred. Doing full sync")
                await fullSync(userId: userId)
                logger.info("Crypto error occurred. Done full sync")
            } else {
                logger.info("Not manual login, getting local shares & items")
                let vaults = try await shareRepository.getVaults(userId: userId)
                try await loadContents(userId: userId, for: vaults)
                logger.info("Not manual login, done getting local shares & items")
            }
        } catch {
            state = .error(error)
        }
    }

    // Delete everything and download again
    @MainActor
    func fullSync(userId: String) async {
        vaultSyncEventStream.send(.started)
        incompleteFullSyncUserId = userId

        do {
            // 1. Delete all local data
            try await deleteLocalDataBeforeFullSync()

            // 2. Get all remote shares and their items
            let remoteShares = try await shareRepository.getRemoteShares(userId: userId,
                                                                         eventStream: vaultSyncEventStream)
            await withThrowingTaskGroup(of: Void.self) { taskGroup in
                for share in remoteShares {
                    taskGroup.addTask { [weak self] in
                        guard let self else { return }
                        try await shareRepository.upsertShares(userId: userId,
                                                               shares: [share],
                                                               eventStream: vaultSyncEventStream)
                        try await itemRepository.refreshItems(userId: userId,
                                                              shareId: share.shareID,
                                                              eventStream: vaultSyncEventStream)
                    }
                }
            }

            // 3. Create default vault if no vaults
            if remoteShares.isEmpty {
                try await createDefaultVault()
            }

            // 4. Load vaults and their contents
            var vaults = try await shareRepository.getVaults(userId: userId)

            // 5. Check if in "forgot password" scenario. Create a new default vault if applicable
            let hasRemoteVaults = remoteShares.contains(where: { $0.shareType == .vault })
            // We see that there are remote vaults but we can't decrypt any of them
            // => "forgot password" happened
            if hasRemoteVaults, vaults.isEmpty {
                try await createDefaultVault()
                vaults = try await shareRepository.getVaults(userId: userId)
            }

            try await loadContents(userId: userId, for: vaults)
        } catch {
            vaultSyncEventStream.send(.error(userId: userId, error: error))
            return
        }

        incompleteFullSyncUserId = nil
        vaultSyncEventStream.send(.done)
    }

    func localFullSync(userId: String) async throws {
        let vaults = try await shareRepository.getVaults(userId: userId)
        try await loadContents(userId: userId, for: vaults)
    }

    func select(_ selection: VaultSelection, filterOption: ItemTypeFilterOption? = nil) {
        pendingItemTypeFilterOption = filterOption
        vaultSelection = selection

        Task { [weak self] in
            guard let self else { return }
            do {
                switch selection {
                case .all, .trash:
                    try await updateUserPreferences(\.lastSelectedShareId, value: nil)
                case let .precise(vault):
                    try await updateUserPreferences(\.lastSelectedShareId, value: vault.shareId)
                }
            } catch {
                logger.error(error)
            }
        }
    }

    func isSelected(_ selection: VaultSelection) -> Bool {
        vaultSelection == selection
    }

    func getItems(for vault: Vault) -> [ItemUiModel] {
        guard case let .loaded(vaults, _) = state else { return [] }

        return vaults.first { $0.vault.id == vault.id }?.items ?? []
    }

    func getAllActiveAndTrashedItems() -> [ItemUiModel] {
        guard case let .loaded(vaults, trashedItems) = state else { return [] }
        let activeItems = vaults.flatMap(\.items)
        return activeItems + trashedItems
    }

    func getAllVaultContents() -> [VaultContentUiModel] {
        guard case let .loaded(vaults, _) = state else { return [] }
        return vaults
    }

    func getAllEditableVaultContents() -> [VaultContentUiModel] {
        getAllVaultContents().filter(\.vault.canEdit)
    }

    func delete(vault: Vault) async throws {
        let shareId = vault.shareId
        logger.trace("Deleting vault \(shareId)")
        try await shareRepository.deleteVault(shareId: shareId)
        logger.trace("Deleting local active items of vault \(shareId)")
        try await itemRepository.deleteAllItemsLocally(shareId: shareId)
        // Delete local items of the vault
        logger.info("Deleted vault \(shareId)")
    }

    func delete(userId: String, shareId: String) async throws {
        logger.trace("Deleting share \(shareId)")
        try await shareRepository.deleteShare(userId: userId, shareId: shareId)
        try await shareRepository.deleteShareLocally(userId: userId, shareId: shareId)
        logger.trace("Deleting local active items of share \(shareId)")
        try await itemRepository.deleteAllItemsLocally(shareId: shareId)
        logger.info("Deleted vault \(shareId)")
    }

    func restoreAllTrashedItems(userId: String) async throws {
        logger.trace("Restoring all trashed items")
        let trashedItems = try await getAllEditableTrashedItems(userId: userId)
        try await itemRepository.untrashItems(trashedItems)
        logger.info("Restored all trashed items")
    }

    func permanentlyDeleteAllTrashedItems(userId: String) async throws {
        logger.trace("Permanently deleting all trashed items")
        let trashedItems = try await getAllEditableTrashedItems(userId: userId)
        try await itemRepository.deleteItems(userId: userId, trashedItems, skipTrash: false)
        logger.info("Permanently deleted all trashed items")
    }

    func getOldestOwnedVault() -> Vault? {
        guard case let .loaded(uiModels, _) = state else { return nil }
        let vaults = uiModels.map(\.vault)
        return vaults.oldestOwned
    }

    func getFilteredItems() -> [ItemUiModel] {
        guard case let .loaded(vaults, trashedItems) = state else { return [] }
        let items: [ItemUiModel] = switch vaultSelection {
        case .all:
            vaults.flatMap(\.items)
        case let .precise(selectedVault):
            vaults
                .filter { $0.vault.shareId == selectedVault.shareId }
                .flatMap(\.items)
        case .trash:
            trashedItems
        }

        switch filterOption {
        case .all:
            return items
        case let .precise(type):
            return items.filter { $0.type == type }
        }
    }

    @MainActor
    func updateItemTypeFilterOption(_ filterOption: ItemTypeFilterOption) {
        self.filterOption = filterOption
    }

    func isItemVisible(_ item: any ItemIdentifiable, type: ItemContentType) -> Bool {
        switch vaultSelection {
        case .all:
            true

        case let .precise(vault):
            if vault.shareId == item.shareId {
                switch filterOption {
                case .all:
                    true
                case let .precise(filterType):
                    filterType == type
                }
            } else {
                false
            }

        case .trash:
            false
        }
    }
}

private extension VaultsManager {
    func getAllEditableTrashedItems(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        let editableShareIds = getAllEditableVaultContents().map(\.vault.shareId)
        let trashedItems = try await itemRepository.getItems(userId: userId, state: .trashed)
        return trashedItems.filter { item in
            editableShareIds.contains(where: { $0 == item.shareId })
        }
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

// MARK: - VaultsProvider

extension VaultsManager: VaultsProvider {
    func getAllVaults() -> [Vault] {
        guard case let .loaded(vaults, _) = state else { return [] }
        return vaults.map(\.vault)
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
