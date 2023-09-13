//
// EditableVaultListViewModel.swift
// Proton Pass - Created on 08/03/2023.
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
import Foundation

protocol EditableVaultListViewModelDelegate: AnyObject {
    func editableVaultListViewModelWantsToConfirmDelete(vault: Vault,
                                                        delegate: DeleteVaultAlertHandlerDelegate)
    func editableVaultListViewModelDidDelete(vault: Vault)
    func editableVaultListViewModelDidRestoreAllTrashedItems()
    func editableVaultListViewModelDidPermanentlyDeleteAllTrashedItems()
}

final class EditableVaultListViewModel: ObservableObject, DeinitPrintable {
    @Published var showingAliasAlert = false
    @Published private(set) var isAllowedToShare = false
    @Published private(set) var loading = false
    @Published private(set) var state = VaultManagerState.loading

    private(set) var numberOfAliasForSharedVault = 0
    let router = resolve(\SharedRouterContainer.mainUIKitSwiftUIRouter)

    private let setShareInviteVault = resolve(\UseCasesContainer.setShareInviteVault)
    private let userSharingStatus = resolve(\UseCasesContainer.userSharingStatus)
    private let getVaultItemCount = resolve(\UseCasesContainer.getVaultItemCount)
    private let leaveShare = resolve(\UseCasesContainer.leaveShare)
    private let syncEventLoop = resolve(\SharedServiceContainer.syncEventLoop)
    private let logger = resolve(\SharedToolingContainer.logger)
    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private var cancellables = Set<AnyCancellable>()

    var hasTrash: Bool {
        vaultsManager.getItemCount(for: .trash) > 0
    }

    weak var delegate: EditableVaultListViewModelDelegate?

    init() {
        setUp()
    }

    deinit { print(deinitMessage) }

    func select(_ selection: VaultSelection) {
        vaultsManager.select(selection)
    }

    func isSelected(_ selection: VaultSelection) -> Bool {
        vaultsManager.isSelected(selection)
    }
}

// MARK: - Private APIs

private extension EditableVaultListViewModel {
    func setUp() {
        vaultsManager.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = state
            }.store(in: &cancellables)

        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            self.isAllowedToShare = await self.userSharingStatus()
        }
    }

    func doDelete(vault: Vault) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.loading = false }
            do {
                self.loading = true
                try await self.vaultsManager.delete(vault: vault)
                self.delegate?.editableVaultListViewModelDidDelete(vault: vault)
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

// MARK: - Public APIs

extension EditableVaultListViewModel {
    func createNewVault() {
        router.present(for: .vaultCreateEdit(vault: nil))
    }

    func edit(vault: Vault) {
        router.present(for: .vaultCreateEdit(vault: vault))
    }

    func share(vault: Vault) {
        setShareInviteVault(with: vault)
        numberOfAliasForSharedVault = getVaultItemCount(for: vault, and: .alias)
        if numberOfAliasForSharedVault > 0 {
            showingAliasAlert = true
        } else {
            router.present(for: .sharingFlow)
        }
    }

    func leaveVault(vault: Vault) {
        Task { @MainActor [weak self] in
            do {
                try await self?.leaveShare(with: vault.shareId)
                self?.syncEventLoop.forceSync()
            } catch {
                self?.logger.error(error)
                self?.router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func delete(vault: Vault) {
        let itemCount = vaultsManager.getItemCount(for: .precise(vault))
        let hasTrashedItems = vaultsManager.vaultHasTrashedItems(vault)
        if itemCount == 0, !hasTrashedItems {
            doDelete(vault: vault)
        } else {
            delegate?.editableVaultListViewModelWantsToConfirmDelete(vault: vault, delegate: self)
        }
    }

    func restoreAllTrashedItems() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.loading = false }
            do {
                self.logger.trace("Restoring all trashed items")
                self.loading = true
                try await self.vaultsManager.restoreAllTrashedItems()
                self.delegate?.editableVaultListViewModelDidRestoreAllTrashedItems()
                self.logger.info("Restored all trashed items")
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(error))
            }
        }
    }

    func emptyTrash() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.loading = false }
            do {
                self.logger.trace("Emptying all trashed items")
                self.loading = true
                try await self.vaultsManager.permanentlyDeleteAllTrashedItems()
                self.delegate?.editableVaultListViewModelDidPermanentlyDeleteAllTrashedItems()
                self.logger.info("Emptied all trashed items")
            } catch {
                self.logger.error(error)
                self.router.display(element: .displayErrorBanner(error))
            }
        }
    }
}

// MARK: - DeleteVaultConfirmationDelegate

extension EditableVaultListViewModel: DeleteVaultAlertHandlerDelegate {
    func confirmDelete(vault: Vault) {
        doDelete(vault: vault)
    }
}
