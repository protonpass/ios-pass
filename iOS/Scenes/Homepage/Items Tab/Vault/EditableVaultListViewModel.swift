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

protocol EditableVaultListViewModelDelegate: AnyObject {
    func editableVaultListViewModelWantsToCreateNewVault()
    func editableVaultListViewModelWantsToEdit(vault: Vault)
}

final class EditableVaultListViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let vaultsManager: VaultsManager

    weak var delegate: EditableVaultListViewModelDelegate?
    private var cancellables = Set<AnyCancellable>()

    init(vaultsManager: VaultsManager) {
        self.vaultsManager = vaultsManager
        self.finalizeInitialization()
    }
}

// MARK: - Private APIs
private extension EditableVaultListViewModel {
    func finalizeInitialization() {
        vaultsManager.attach(to: self, storeIn: &cancellables)
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
        print(#function)
    }

    func restoreAllTrashedItems() {
        print(#function)
    }

    func emptyTrash() {
        print(#function)
    }
}
