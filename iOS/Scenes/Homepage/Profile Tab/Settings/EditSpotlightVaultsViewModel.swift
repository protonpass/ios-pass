//
// EditSpotlightVaultsViewModel.swift
// Proton Pass - Created on 01/02/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Entities
import Factory
import Foundation

final class EditSpotlightVaultsViewModel: ObservableObject {
    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private let currentSpotlightSelectedVaults = resolve(\DataStreamContainer
        .currentSpotlightSelectedVaults)
    @Published private(set) var selectedVaults = [Share]()

    let allVaults: [VaultListUiModel]

    init() {
        allVaults = vaultsManager.getAllVaultContents().map { .init(vaultContent: $0) }
        selectedVaults = currentSpotlightSelectedVaults.value
    }

    func toggleSelection(vault: Share) {
        if isSelected(vault: vault) {
            selectedVaults.removeAll(where: { $0 == vault })
        } else {
            selectedVaults.append(vault)
        }
        currentSpotlightSelectedVaults.send(selectedVaults)
    }

    func isSelected(vault: Share) -> Bool {
        selectedVaults.contains(where: { $0.shareId == vault.shareId })
    }
}
