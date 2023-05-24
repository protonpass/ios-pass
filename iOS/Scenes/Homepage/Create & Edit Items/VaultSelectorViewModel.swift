//
// VaultSelectorViewModel.swift
// Proton Pass - Created on 24/05/2023.
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

protocol VaultSelectorViewModelDelegate: AnyObject {
    func vaultSelectorViewModelWantsToUpgrade()
    func vaultSelectorViewModelDidSelect(vault: Vault)
    func vaultSelectorViewModelDidEncounter(error: Error)
}

final class VaultSelectorViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let allVaults: [VaultListUiModel]

    @Published private(set) var selectedVault: Vault
    @Published private(set) var onlyPrimaryVaultIsAllowed = false

    weak var delegate: VaultSelectorViewModelDelegate?

    init(allVaults: [VaultListUiModel],
         selectedVault: Vault,
         upgradeChecker: UpgradeCheckerProtocol,
         logManager: LogManager) {
        self.allVaults = allVaults
        self.selectedVault = selectedVault

        Task { @MainActor in
            guard allVaults.count > 1 else { return }
            do {
                onlyPrimaryVaultIsAllowed = try await upgradeChecker.isFreeUser()
                if onlyPrimaryVaultIsAllowed,
                   let primaryVault = allVaults.first(where: { $0.vault.isPrimary }) {
                    self.selectedVault = primaryVault.vault
                }
            } catch {
                let logger = Logger(manager: logManager)
                logger.error(error)
                delegate?.vaultSelectorViewModelDidEncounter(error: error)
            }
        }
    }

    func select(vault: Vault) {
        delegate?.vaultSelectorViewModelDidSelect(vault: vault)
    }

    func upgrade() {
        delegate?.vaultSelectorViewModelWantsToUpgrade()
    }
}
