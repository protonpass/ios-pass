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
            return "Search in all vaults"
        case .precise(let vault):
            return "Search in \(vault.name)"
        case .trash:
            return "Search in trash"
        }
    }
}

final class VaultsManager: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let itemRepository: ItemRepositoryProtocol
    private let manualLogIn: Bool
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
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
        self.shareRepository = shareRepository
        self.symmetricKey = symmetricKey
    }
}

// MARK: - Private APIs
private extension VaultsManager {
    func createDefaultVault() async throws {
        let vault = VaultProtobuf(name: "Personal",
                                  description: "Personal vault",
                                  color: .color1,
                                  icon: .icon1)
        try await shareRepository.createVault(vault)
    }

    @MainActor
    func loadContents(for vaults: [Vault]) async throws {
        let uiModels = try await vaults.parallelMap { vault in
            let items = try await self.itemRepository.getItems(shareId: vault.shareId, state: .active)
            let itemUiModels = try items.map { try $0.toItemUiModel(self.symmetricKey) }
            return VaultContentUiModel(vault: vault, items: itemUiModels)
        }

        let trashedItems =
        try await itemRepository.getItems(state: .trashed).map { try $0.toItemUiModel(symmetricKey) }

        state = .loaded(vaults: uiModels, trashedItems: trashedItems)

        // Reset to `all` when last selected vault is deleted
        if case .precise(let selectedVault) = vaultSelection {
            if !vaults.contains(where: { $0 == selectedVault }) {
                vaultSelection = .all
            }
        }
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
                    try await itemRepository.refreshItems()
                    let vaults = try await shareRepository.getVaults()
                    if vaults.isEmpty {
                        let userId = shareRepository.userData.user.ID
                        logger.trace("Creating default vault for user \(userId)")
                        try await createDefaultVault()
                        logger.trace("Created default vault for user \(userId)")
                        let vaults = try await shareRepository.getVaults()
                        try await loadContents(for: vaults)
                    } else {
                        try await loadContents(for: vaults)
                    }
                } else {
                    let vaults = try await shareRepository.getVaults()
                    try await loadContents(for: vaults)
                }
            } catch {
                state = .error(error)
            }
        }
    }

    /// Refresh by 1) removing the `trashedItem` from the containing vault
    /// And 2) add it to `trashedItems` to make the refresh process quicker comparing to a full refresh
    func refresh(trashedItem: ItemIdentifiable) {
        Task { @MainActor in
            do {
                guard case var .loaded(vaults, trashedItems) = state else { return }

                // 1: Find the vault that contains `trashedItem` then manually remove it
                if var updatedVault = vaults.first(where: { $0.items.contains(trashedItem) }) {
                    updatedVault = .init(vault: updatedVault.vault,
                                         items: updatedVault.items.removing(item: trashedItem))
                    if let index = vaults.firstIndex(where: { $0.vault.id == updatedVault.vault.id }) {
                        vaults[index] = updatedVault
                    }
                }

                // 2: Get the full detail of `trashedItem` and append to `trashedItem` array
                if let item = try await itemRepository.getItem(shareId: trashedItem.shareId,
                                                               itemId: trashedItem.itemId) {
                    let uiModel = try item.toItemUiModel(itemRepository.symmetricKey)
                    trashedItems.append(uiModel)
                }

                state = .loaded(vaults: vaults, trashedItems: trashedItems)
            } catch {
                state = .error(error)
            }
        }
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

    func getVaultCount() -> Int {
        switch state {
        case let .loaded(vaults, _):
            return vaults.count
        default:
            return 0
        }
    }

    func restoreAllTrashedItems() async throws {
        let userId = shareRepository.userData.user.ID
        logger.trace("Restoring all trashed items for user \(userId)")
        let trashedItems = try await itemRepository.getItems(state: .trashed)
        try await itemRepository.untrashItems(trashedItems)
        logger.info("Restored all trashed items for user \(userId)")
    }

    func permanentlyDeleteAllTrashedItems() async throws {
        let userId = shareRepository.userData.user.ID
        logger.trace("Permanently deleting all trashed items for user \(userId)")
        let trashedItems = try await itemRepository.getItems(state: .trashed)
        try await itemRepository.deleteItems(trashedItems, skipTrash: false)
        logger.info("Permanently deleted all trashed items for user \(userId)")
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
            return lhsError.messageForTheUser == rhsError.messageForTheUser
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
