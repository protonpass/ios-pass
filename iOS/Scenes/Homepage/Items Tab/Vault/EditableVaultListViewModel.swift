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

protocol EditableVaultListViewModelDelegate: AnyObject {
    func editableVaultListViewModelWantsToShowSpinner()
    func editableVaultListViewModelWantsToHideSpinner()
    func editableVaultListViewModelWantsToCreateNewVault()
    func editableVaultListViewModelWantsToEdit(vault: Vault)
    func editableVaultListViewModelWantsToConfirmDelete(vault: Vault,
                                                        delegate: DeleteVaultAlertHandlerDelegate)
    func editableVaultListViewModelDidDelete(vault: Vault)
    func editableVaultListViewModelDidEncounter(error: Error)
    func editableVaultListViewModelDidRestoreAllTrashedItems()
    func editableVaultListViewModelDidPermanentlyDeleteAllTrashedItems()
}

final class EditableVaultListViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var showingAlert = false

    private let setShareInviteVault = resolve(\UseCasesContainer.setShareInviteVault)
    private(set) var numberOfAliasforSharedVault = 0

    private let logger: Logger
    let vaultsManager: VaultsManager

    weak var delegate: EditableVaultListViewModelDelegate?
    private var cancellables = Set<AnyCancellable>()

    init(vaultsManager: VaultsManager, logManager: LogManagerProtocol) {
        self.vaultsManager = vaultsManager
        logger = .init(manager: logManager)
        finalizeInitialization()
    }
}

// MARK: - Private APIs

private extension EditableVaultListViewModel {
    func finalizeInitialization() {
        vaultsManager.attach(to: self, storeIn: &cancellables)
    }

    func doDelete(vault: Vault) {
        Task { @MainActor in
            defer { delegate?.editableVaultListViewModelWantsToHideSpinner() }
            do {
                delegate?.editableVaultListViewModelWantsToShowSpinner()
                try await vaultsManager.delete(vault: vault)
                delegate?.editableVaultListViewModelDidDelete(vault: vault)
            } catch {
                logger.error(error)
                delegate?.editableVaultListViewModelDidEncounter(error: error)
            }
        }
    }
}

// MARK: - Public APIs

extension EditableVaultListViewModel {
    func createNewVault() {
        delegate?.editableVaultListViewModelWantsToCreateNewVault()
    }

    func edit(vault: Vault) {
        delegate?.editableVaultListViewModelWantsToEdit(vault: vault)
    }

    func share(vault: Vault) {
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            let numberOfItems = vaultsManager.getItem(for: vault)
            await self.setShareInviteVault(with: vault, and: numberOfItems.count)
            self.numberOfAliasforSharedVault = numberOfItems.filter { $0.type == .alias }.count
            self.showingAlert = true
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
        Task { @MainActor in
            defer { delegate?.editableVaultListViewModelWantsToHideSpinner() }
            do {
                logger.trace("Restoring all trashed items")
                delegate?.editableVaultListViewModelWantsToShowSpinner()
                try await vaultsManager.restoreAllTrashedItems()
                delegate?.editableVaultListViewModelDidRestoreAllTrashedItems()
                logger.info("Restored all trashed items")
            } catch {
                logger.error(error)
                delegate?.editableVaultListViewModelDidEncounter(error: error)
            }
        }
    }

    func emptyTrash() {
        Task { @MainActor in
            defer { delegate?.editableVaultListViewModelWantsToHideSpinner() }
            do {
                logger.trace("Emptying all trashed items")
                delegate?.editableVaultListViewModelWantsToShowSpinner()
                try await vaultsManager.permanentlyDeleteAllTrashedItems()
                delegate?.editableVaultListViewModelDidPermanentlyDeleteAllTrashedItems()
                logger.info("Emptied all trashed items")
            } catch {
                logger.error(error)
                delegate?.editableVaultListViewModelDidEncounter(error: error)
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
