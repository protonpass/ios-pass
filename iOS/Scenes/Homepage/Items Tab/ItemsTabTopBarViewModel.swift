//
// ItemsTabTopBarViewModel.swift
// Proton Pass - Created on 30/11/2023.
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
import Entities
import Factory
import Macro
import SwiftUI

extension VaultSelection {
    var accessibilityLabel: String {
        switch self {
        case .all:
            #localized("Show all vaults")
        case let .precise(vault):
            #localized("Show %@ vault", vault.name)
        case .trash:
            #localized("Show trash")
        }
    }
}

enum TogglePinningOption {
    case pin, unpin
}

final class ItemsTabTopBarViewModel: ObservableObject {
    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private let currentSelectedItems = resolve(\DataStreamContainer.currentSelectedItems)
    private var cancellables = Set<AnyCancellable>()

    @Published private(set) var actionsDisabled = true
    @Published private(set) var togglePinningOption: TogglePinningOption = .pin

    var selectedItemsCount: Int {
        currentSelectedItems.value.count
    }

    var vaultSelection: VaultSelection {
        vaultsManager.vaultSelection
    }

    init() {
        vaultsManager.attach(to: self, storeIn: &cancellables)
        actionsDisabled = currentSelectedItems.value.isEmpty
        currentSelectedItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                guard let self else { return }
                actionsDisabled = items.isEmpty
                togglePinningOption = items.allSatisfy(\.pinned) ? .unpin : .pin
            }
            .store(in: &cancellables)
    }
}

extension ItemsTabTopBarViewModel {
    func deselectAllItems() {
        currentSelectedItems.send([])
    }
}
