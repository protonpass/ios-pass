//
// ItemsTabViewModel.swift
// Proton Pass - Created on 07/03/2023.
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

import Combine
import Core

protocol ItemsTabViewModelDelegate: AnyObject {
    func itemsTabViewModelWantsToSearch()
    func itemsTabViewModelWantsToPresentVaultList()
}

final class ItemsTabViewModel: ObservableObject, DeinitPrintable {
    deinit { print(deinitMessage) }

    let vaultsManager: VaultsManager

    weak var delegate: ItemsTabViewModelDelegate?

    private var cancellables = Set<AnyCancellable>()

    init(vaultsManager: VaultsManager) {
        self.vaultsManager = vaultsManager
    }
}

// MARK: - Private APIs
private extension ItemsTabViewModel {
    func finalizeInitialization() {
        vaultsManager.attach(to: self, storeIn: &cancellables)
    }
}

// MARK: - Public APIs
extension ItemsTabViewModel {
    func search() {
        delegate?.itemsTabViewModelWantsToSearch()
    }

    func presentVaultList() {
        delegate?.itemsTabViewModelWantsToPresentVaultList()
    }
}
