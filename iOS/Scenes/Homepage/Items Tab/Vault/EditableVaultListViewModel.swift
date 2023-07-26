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

    private let logger = resolve(\SharedToolingContainer.logger)
    let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)

    weak var delegate: EditableVaultListViewModelDelegate?
    private var cancellables = Set<AnyCancellable>()

    init() {
        setUp()
    }
}

// MARK: - Private APIs

private extension EditableVaultListViewModel {
    func setUp() {
        vaultsManager.attach(to: self, storeIn: &cancellables)
    }

    func doDelete(vault: Vault) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.delegate?.editableVaultListViewModelWantsToHideSpinner() }
            do {
                self.delegate?.editableVaultListViewModelWantsToShowSpinner()
                try await self.vaultsManager.delete(vault: vault)
                self.delegate?.editableVaultListViewModelDidDelete(vault: vault)
            } catch {
                self.logger.error(error)
                self.delegate?.editableVaultListViewModelDidEncounter(error: error)
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
            defer { self.delegate?.editableVaultListViewModelWantsToHideSpinner() }
            do {
                self.logger.trace("Restoring all trashed items")
                self.delegate?.editableVaultListViewModelWantsToShowSpinner()
                try await self.vaultsManager.restoreAllTrashedItems()
                self.delegate?.editableVaultListViewModelDidRestoreAllTrashedItems()
                self.logger.info("Restored all trashed items")
            } catch {
                self.logger.error(error)
                self.delegate?.editableVaultListViewModelDidEncounter(error: error)
            }
        }
    }

    func emptyTrash() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            defer { self.delegate?.editableVaultListViewModelWantsToHideSpinner() }
            do {
                self.logger.trace("Emptying all trashed items")
                self.delegate?.editableVaultListViewModelWantsToShowSpinner()
                try await self.vaultsManager.permanentlyDeleteAllTrashedItems()
                self.delegate?.editableVaultListViewModelDidPermanentlyDeleteAllTrashedItems()
                self.logger.info("Emptied all trashed items")
            } catch {
                self.logger.error(error)
                self.delegate?.editableVaultListViewModelDidEncounter(error: error)
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
