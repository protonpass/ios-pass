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
    case loaded([VaultContentUiModel])
    case error(Error)
}

extension VaultManagerState: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case let (.loaded(lhsVaults), .loaded(rhsVaults)):
            return lhsVaults.hashValue == rhsVaults.hashValue
        case let (.error(lhsError), .error(rhsError)):
            return lhsError.messageForTheUser == rhsError.messageForTheUser
        default:
            return false
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
    private let userData: UserData

    @Published private(set) var state = VaultManagerState.loading
    @Published private(set) var selectedVault: Vault?

    var vaultCount: Int {
        switch state {
        case .loaded(let vaults):
            return vaults.count
        default:
            return 0
        }
    }

    var itemCount: Int {
        switch state {
        case .loaded(let vaults):
            if let selectedVault {
                return vaults.first { $0.vault == selectedVault }?.items.count ?? 0
            } else {
                return vaults.map { $0.items.count }.reduce(0) { $0 + $1 }
            }
        default:
            return 0
        }
    }

    init(itemRepository: ItemRepositoryProtocol,
         manualLogIn: Bool,
         logManager: LogManager,
         shareRepository: ShareRepositoryProtocol,
         symmetricKey: SymmetricKey,
         userData: UserData) {
        self.itemRepository = itemRepository
        self.manualLogIn = manualLogIn
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
        self.shareRepository = shareRepository
        self.symmetricKey = symmetricKey
        self.userData = userData
    }

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
                        let userId = userData.user.ID
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
}

// MARK: - Private APIs
private extension VaultsManager {
    func createDefaultVault() async throws {
        logger.info("Creating default vault")
        let request = try CreateVaultRequest(userData: userData,
                                             name: "Personal",
                                             description: "Personal vault")
        try await shareRepository.createVault(request: request)
        logger.info("Created default vault")
    }

    @MainActor
    func loadContents(for vaults: [Vault]) async throws {
        let uiModels = try await vaults.parallelMap { vault in
            let items = try await self.itemRepository.getItems(shareId: vault.shareId, state: .active)
            let itemUiModels = try items.map { try $0.toItemUiModel(self.symmetricKey) }
            return VaultContentUiModel(vault: vault,
                                       items: itemUiModels)
        }
        state = .loaded(uiModels)

        if !vaults.contains(where: { $0 == selectedVault }) {
            selectedVault = vaults.first
        }
    }
}

// MARK: - Public APIs
extension VaultsManager {
    func select(vault: Vault) {
        guard vault != selectedVault else { return }
        selectedVault = vault
    }

    func getSelectedVaultItems() -> [ItemUiModel] {
        guard let selectedVault, case .loaded(let vaults) = state else { return [] }
        return vaults.first { $0.vault == selectedVault }?.items ?? []
    }

    func getAllItems() -> [ItemUiModel] {
        guard case .loaded(let vaults) = state else { return [] }
        return vaults.map { $0.items }.reduce(into: []) { $0 += $1 }
    }
}
