//
// VaultListViewModel.swift
// Proton Pass - Created on 28/12/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import SwiftUI

protocol VaultListViewModelDelegate: AnyObject {
    func vaultListViewModelWantsToCreateVault()
}

final class VaultListViewModel: ObservableObject {
    var vaults: [VaultProtocol] { vaultSelection.vaults }
    var selectedVault: VaultProtocol? { vaultSelection.selectedVault }

    private let vaultSelection: VaultSelection
    private var cancellables: AnyCancellable?
    weak var delegate: VaultListViewModelDelegate?

    init(vaultSelection: VaultSelection) {
        self.vaultSelection = vaultSelection
        cancellables = vaultSelection.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
    }
}

extension VaultListViewModel {
    func createVault() {
        delegate?.vaultListViewModelWantsToCreateVault()
    }

    func selectVault(_ vault: VaultProtocol) {
        vaultSelection.update(selectedVault: vault)
    }
}
