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
import Combine
import Core
import Factory

protocol VaultSelectorViewModelDelegate: AnyObject {
    func vaultSelectorViewModelDidSelect(vault: Vault)
}

final class VaultSelectorViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let getFeatureFlagStatus = resolve(\SharedUseCasesContainer.getFeatureFlagStatus)
    private let getMainVault = resolve(\SharedUseCasesContainer.getMainVault)

    let allVaults: [VaultListUiModel]

    @Published private(set) var selectedVault: Vault
    @Published private(set) var isFreeUser = false

    weak var delegate: VaultSelectorViewModelDelegate?

    private var isPrimaryVaultRemoved = false

    init(allVaults: [VaultListUiModel], selectedVault: Vault) {
        self.allVaults = allVaults
        self.selectedVault = selectedVault

        setup()
    }

    func select(vault: Vault) {
        delegate?.vaultSelectorViewModelDidSelect(vault: vault)
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }

    func shouldReduceOpacity(for vault: Vault) -> Bool {
        guard !isPrimaryVaultRemoved else {
            return false
        }
        return isFreeUser && !vault.isPrimary
    }
}

private extension VaultSelectorViewModel {
    func setup() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            isPrimaryVaultRemoved = await getFeatureFlagStatus(with: FeatureFlagType.passRemovePrimaryVault)
            guard allVaults.count > 1 else { return }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
                if isFreeUser, let mainVault = await getMainVault() {
                    selectedVault = mainVault
                }
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}
