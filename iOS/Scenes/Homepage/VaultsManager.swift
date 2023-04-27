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
import Core
import CryptoKit
import ProtonCore_Login

enum VaultManagerState {
    case loading
    case loaded(vaults: [VaultContentUiModel], trashedItems: [ItemUiModel])
    case error(Error)
}

enum VaultSelection {
    case all
    case precise(Vault)
    case trash

    var searchBarPlacehoder: String {
        switch self {
        case .all:
            return "Search in all vaults..."
        case .precise(let vault):
            return "Search in \(vault.name)..."
        case .trash:
            return "Search in trash..."
        }
    }
}

final class VaultsManager: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let itemRepository: ItemRepositoryProtocol
    private var manualLogIn: Bool
    private let logger: Logger
    private let shareRepository: ShareRepositoryProtocol
    private let symmetricKey: SymmetricKey

    @Published private(set) var state = VaultManagerState.loading
    @Published private(set) var vaultSelection = VaultSelection.all

    init(itemRepository: ItemRepositoryProtocol,
         manualLogIn: Bool,
         logManager: LogManager,
         shareRepository: ShareRepositoryProtocol,
         symmetricKey: SymmetricKey) {
        self.itemRepository = itemRepository
        self.manualLogIn = manualLogIn
        self.logger = .init(manager: logManager)
        self.shareRepository = shareRepository
        self.symmetricKey = symmetricKey
        self.refresh()
    }
}

// MARK: - Private APIs
private extension VaultsManager {
    @MainActor
    func createDefaultVault() async throws {
        let userId = shareRepository.userData.user.ID
        logger.trace("Creating default vault for user \(userId)")
        let vault = VaultProtobuf(name: "Personal",
                                  description: "Personal vault",
                                  color: .color1,
                                  icon: .icon1)
        try await shareRepository.createVault(vault)
        logger.trace("Created default vault for user \(userId)")
    }

    @MainActor
    func loadContents(for vaults: [Vault]) async throws {
        let allItems = try await itemRepository.getAllItems()
        let allItemUiModels = try allItems.map { try $0.toItemUiModel(symmetricKey) }

        var vaultContentUiModels = vaults.map { vault in
            let items = allItemUiModels
                .filter { $0.shareId == vault.shareId }
                .filter { $0.state == .active }
            return VaultContentUiModel(vault: vault, items: items)
        }
        vaultContentUiModels.sortAlphabetically()

        let trashedItems = allItemUiModels.filter { $0.state == .trashed }

        // Reset to `all` when last selected vault is deleted
        if case .precise(let selectedVault) = vaultSelection {
            if !vaults.contains(where: { $0 == selectedVault }) {
                vaultSelection = .all
            }
        }

        state = .loaded(vaults: vaultContentUiModels, trashedItems: trashedItems)
    }
}

// MARK: - Public APIs
extension VaultsManager {
    func refresh() {
        Task { @MainActor in
            do {
                // No need to show loading indicator once items are loaded beforehand.
                switch state {
                case .loaded:
                    break
                default:
                    state = .loading
                }

                if manualLogIn {
                    logger.info("Manual login, doing full sync")
                    try await fullSync()
                    manualLogIn = false
                    logger.info("Manual login, done full sync")
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
    }

    func fullSync() async throws {
        // 1. Delete all local items & shares
        try await itemRepository.deleteAllItemsLocally()
        try await shareRepository.deleteAllSharesLocally()

        // 2. Get all remote shares and their items
        let remoteShares = try await shareRepository.getRemoteShares()
        await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for share in remoteShares {
                taskGroup.addTask { [unowned self] in
                    try await self.shareRepository.upsertShares([share])
                    try await self.itemRepository.refreshItems(shareId: share.shareID)
                }
            }
        }

        // 3. Create default vault if not any
        if remoteShares.isEmpty {
            try await createDefaultVault()
        }

        // 4. Load vaults and their contents
        let vaults = try await shareRepository.getVaults()
        try await loadContents(for: vaults)
    }

    func select(_ selection: VaultSelection) {
        vaultSelection = selection
    }

    func isSelected(_ selection: VaultSelection) -> Bool {
        vaultSelection == selection
    }

    func getItem(for selection: VaultSelection) -> [ItemUiModel] {
        guard case let .loaded(vaults, trashedItems) = state else { return [] }
        switch vaultSelection {
        case .all:
            return vaults.map { $0.items }.reduce(into: []) { $0 += $1 }
        case .precise(let selectedVault):
            return vaults.first { $0.vault == selectedVault }?.items ?? []
        case  .trash:
            return trashedItems
        }
    }

    func getItemCount(for selection: VaultSelection) -> Int {
        guard case let .loaded(vaults, trashedItems) = state else { return 0 }
        switch selection {
        case .all:
            return vaults.map { $0.items.count }.reduce(into: 0) { $0 += $1 }
        case .precise(let vault):
            return vaults.first { $0.vault == vault }?.items.count ?? 0
        case .trash:
            return trashedItems.count
        }
    }

    func getAllVaultContents() -> [VaultContentUiModel] {
        guard case let .loaded(vaults, _) = state else { return [] }
        return vaults
    }

    func getAllVaults() -> [Vault] {
        guard case let .loaded(vaults, _) = state else { return [] }
        return vaults.map { $0.vault }
    }

    func getVaultCount() -> Int {
        switch state {
        case let .loaded(vaults, _):
            return vaults.count
        default:
            return 0
        }
    }

    func delete(vault: Vault) async throws {
        logger.trace("Deleting vault \(vault.shareId)")
        try await shareRepository.deleteVault(shareId: vault.shareId)
        switch state {
        case let .loaded(vaults, _):
            if let deletedVault = vaults.first(where: { $0.vault.shareId == vault.shareId }) {
                let itemIds = deletedVault.items.map { $0.itemId }
                try await itemRepository.deleteItemsLocally(itemIds: itemIds, shareId: vault.shareId)
            }
        default:
            break
        }
        // Delete local items of the vault
        logger.info("Deleted vault \(vault.shareId)")
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

    func getPrimaryVault() -> Vault? {
        guard case .loaded(let uiModels, _) = state else { return nil }
        let vaults = uiModels.map { $0.vault }
        return vaults.first(where: { $0.isPrimary }) ?? vaults.first
    }

    func getSelectedShareId() -> String? {
        switch vaultSelection {
        case .all, .trash:
            return getPrimaryVault()?.shareId
        case .precise(let vault):
            return vault.shareId
        }
    }
}

extension VaultManagerState: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case let (.loaded(lhsVaults, lhsTrashedItems), .loaded(rhsVaults, rhsTrashedItems)):
            return lhsVaults.hashValue == rhsVaults.hashValue &&
            lhsTrashedItems.hashValue == rhsTrashedItems.hashValue
        case let (.error(lhsError), .error(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

extension VaultSelection: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.all, .all), (.trash, .trash):
            return true
        case let (.precise(lhsVault), .precise(rhsVault)):
            return lhsVault.id == rhsVault.id && lhsVault.shareId == rhsVault.shareId
        default:
            return false
        }
    }
}
