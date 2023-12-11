//
// ItemsTabOptionsButtonViewModel.swift
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

import Client
import Combine
import Core
import Factory
import Foundation
import SwiftUI

@MainActor
final class ItemsTabOptionsButtonViewModel: ObservableObject {
    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private var cancellables = Set<AnyCancellable>()

    @AppStorage(Constants.sortTypeKey, store: kSharedUserDefaults)
    var selectedSortType = SortType.mostRecent

    var selectedFilterOption: ItemTypeFilterOption {
        vaultsManager.filterOption
    }

    var itemCount: ItemCount {
        vaultsManager.itemCount
    }

    var selectable: Bool {
        switch vaultsManager.vaultSelection {
        case .all, .trash:
            true
        case let .precise(vault):
            vault.canEdit
        }
    }

    var highlighted: Bool {
        vaultsManager.filterOption != .all
    }

    var resettable: Bool {
        vaultsManager.filterOption != .all || selectedSortType != .mostRecent
    }

    init() {
        vaultsManager.attach(to: self, storeIn: &cancellables)
    }

    func updateFilterOption(_ option: ItemTypeFilterOption) {
        vaultsManager.updateItemTypeFilterOption(option)
    }

    func resetFilters() {
        vaultsManager.updateItemTypeFilterOption(.all)
        selectedSortType = .mostRecent
    }
}
