//
// MoveVaultListViewModel.swift
// Proton Pass - Created on 29/03/2023.
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

final class MoveVaultListViewModel: ObservableObject, DeinitPrintable, Sendable {
    deinit { print(deinitMessage) }

    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let moveItemsBetweenVaults = resolve(\UseCasesContainer.moveItemsBetweenVaults)
    private let getVaultContentForVault = resolve(\UseCasesContainer.getVaultContentForVault)

    @Published private(set) var isFreeUser = false
    @Published var selectedVault: VaultContentUiModel

    let allVaults: [VaultContentUiModel]
    private let currentVault: VaultContentUiModel
    private let itemContent: ItemContent?

    init(allVaults: [VaultContentUiModel], currentVault: Vault, itemContent: ItemContent?) {
        self.allVaults = allVaults
        self.currentVault = getVaultContentForVault(for: currentVault)
        self.itemContent = itemContent
        selectedVault = self.currentVault

        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                self.isFreeUser = try await self.upgradeChecker.isFreeUser()
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }

    func doMove() {
        guard selectedVault != currentVault else { return }

        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.router.display(element: .globalLoading(shouldShow: false)) }
            do {
                self.router.display(element: .globalLoading(shouldShow: true))
                try await self.moveItemsBetweenVaults(from: currentVault.vault.shareId,
                                                      or: itemContent,
                                                      to: selectedVault.vault.shareId)
                router.display(element: self.createMoveSuccessMessage)
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

private extension MoveVaultListViewModel {
    var createMoveSuccessMessage: UIElementDisplay {
        if let itemContent {
            return UIElementDisplay.successMessage("Item moved to vault \"\(selectedVault.vault.name)\"",
                                                   config: NavigationActions(dismissBeforeShowing: true,
                                                                             refresh: true,
                                                                             telemetryEvent: .update(itemContent
                                                                                 .type)))
        } else {
            return UIElementDisplay
                .successMessage("Items from \(currentVault.vault.name) moved to vault \"\(selectedVault.vault.name)\"",
                                config: NavigationActions(dismissBeforeShowing: true,
                                                          refresh: true))
        }
    }
}
