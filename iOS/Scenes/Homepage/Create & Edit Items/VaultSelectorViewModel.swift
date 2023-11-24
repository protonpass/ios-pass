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
import Entities
import Factory

final class VaultSelectorViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let getMainVault = resolve(\SharedUseCasesContainer.getMainVault)
    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)

    let allVaults: [VaultListUiModel]

    @Published private(set) var selectedVault: Vault?
    @Published private(set) var isFreeUser = false

    init() {
        allVaults = vaultsManager.getAllEditableVaultContents().map { .init(vaultContent: $0) }
        selectedVault = vaultsManager.vaultSelection.preciseVault

        setup()
    }

    func select(vault: Vault) {
        vaultsManager.select(.precise(vault))
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }
}

private extension VaultSelectorViewModel {
    func setup() {
        Task { @MainActor [weak self] in
            guard let self else { return }
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
