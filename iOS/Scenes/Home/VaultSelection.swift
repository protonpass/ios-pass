//
// VaultSelection.swift
// Proton Pass - Created on 21/07/2022.
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
import Core

/// Holds current list of vaults and selected vault
final class VaultSelection: ObservableObject {
    @Published private(set) var selectedVault: VaultProtocol?
    @Published private(set) var vaults: [VaultProtocol]

    init(vaults: [VaultProtocol]) {
        self._selectedVault = .init(initialValue: nil)
        self._vaults = .init(initialValue: vaults)
    }

    func update(vaults: [VaultProtocol]) {
        self.vaults = vaults
        self.selectedVault = vaults.first
    }

    func update(selectedVault: VaultProtocol?) {
        self.selectedVault = selectedVault
    }
}
