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
import Entities
import Factory
import Macro

@MainActor
final class MoveVaultListViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    private let upgradeChecker = resolve(\SharedServiceContainer.upgradeChecker)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)
    private let moveItemsBetweenVaults = resolve(\UseCasesContainer.moveItemsBetweenVaults)
    private let getVaultContentForVault = resolve(\UseCasesContainer.getVaultContentForVault)
    private let currentSelectedItems = resolve(\DataStreamContainer.currentSelectedItems)

    @Published private(set) var isFreeUser = false
    @Published var selectedVault: VaultContentUiModel?

    let allVaults: [VaultContentUiModel]
    private let context: MovingContext

    init(allVaults: [VaultContentUiModel], context: MovingContext) {
        self.allVaults = allVaults
        self.context = context
        let fromShareId: String? = switch context {
        case let .singleItem(item):
            item.shareId
        case let .allItems(vault):
            vault.shareId
        case .selectedItems:
            nil
        }

        if let fromShareId {
            selectedVault = getVaultContentForVault(for: fromShareId)
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                isFreeUser = try await upgradeChecker.isFreeUser()
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func upgrade() {
        router.present(for: .upgradeFlow)
    }

    func doMove() {
        guard let selectedVault, selectedVault.vault.isVaultRepresentation,
              let vaultContent = selectedVault.vault.vaultContent else {
            assertionFailure("Should have a selected vault")
            return
        }
        Task { [weak self] in
            guard let self else { return }
            defer { router.display(element: .globalLoading(shouldShow: false)) }
            do {
                router.display(element: .globalLoading(shouldShow: true))
                try await moveItemsBetweenVaults(context: context,
                                                 to: selectedVault.vault.shareId)
                router.display(element: successMessage(toVaultName: vaultContent.name))
                currentSelectedItems.send([])
            } catch {
                logger.error(error)
                router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

private extension MoveVaultListViewModel {
    func successMessage(toVaultName: String) -> UIElementDisplay {
        switch context {
        case let .singleItem(item):
            let message = #localized("Item moved to vault « %@ »", toVaultName)
            return .successMessage(message, config: .dismissAndRefresh(with: .update(item.type)))
        case let .allItems(fromVault):
            let message = #localized("Items from « %@ » moved to vault « %@ »", fromVault.vaultName ?? "",
                                     toVaultName)
            return .successMessage(message, config: .dismissAndRefresh)
        case let .selectedItems(items):
            let message = #localized("%lld items moved to vault « %@ »", items.count, toVaultName)
            return .successMessage(message, config: .dismissAndRefresh)
        }
    }
}
