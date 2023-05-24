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
import Core

protocol MoveVaultListViewModelDelegate: AnyObject {
    func moveVaultListViewModelDidPick(vault: Vault)
}

final class MoveVaultListViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    @Published var selectedVault: VaultListUiModel

    weak var delegate: MoveVaultListViewModelDelegate?

    let allVaults: [VaultListUiModel]
    let currentVault: VaultListUiModel

    init(allVaults: [VaultListUiModel], currentVault: VaultListUiModel) {
        self.allVaults = allVaults
        self.currentVault = currentVault
        self.selectedVault = currentVault
    }

    func confirm() {
        guard selectedVault != currentVault else { return }
        delegate?.moveVaultListViewModelDidPick(vault: selectedVault.vault)
    }
}
