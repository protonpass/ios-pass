//
// SearchResultsViewModel.swift
// Proton Pass - Created on 09/08/2023.
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
import Entities
import Factory
import SwiftUI

@MainActor
final class SearchResultsViewModel: ObservableObject {
    @Published var itemToBePermanentlyDeleted: (any ItemTypeIdentifiable)? {
        didSet {
            if itemToBePermanentlyDeleted != nil {
                showingPermanentDeletionAlert = true
            }
        }
    }

    @Published var showingPermanentDeletionAlert = false

    private let vaultsManager = resolve(\SharedServiceContainer.vaultsManager)
    private let canEditItem = resolve(\SharedUseCasesContainer.canEditItem)
    @LazyInjected(\SharedUseCasesContainer.getFeatureFlagStatus) private var getFeatureFlagStatus

    let itemContextMenuHandler: ItemContextMenuHandler
    let itemCount: ItemCount
    let results: any SearchResults
    let isTrash: Bool

    lazy var aliasSyncEnabled = getFeatureFlagStatus(with: FeatureFlagType.passSimpleLoginAliasesSync)

    init(itemContextMenuHandler: ItemContextMenuHandler,
         itemCount: ItemCount,
         results: any SearchResults,
         isTrash: Bool) {
        self.itemContextMenuHandler = itemContextMenuHandler
        self.itemCount = itemCount
        self.results = results
        self.isTrash = isTrash
    }
}

// MARK: Public APIs

extension SearchResultsViewModel {
    func permanentlyDelete() {
        guard let itemToBePermanentlyDeleted else { return }
        itemContextMenuHandler.deletePermanently(itemToBePermanentlyDeleted)
    }

    func isEditable(_ item: any ItemIdentifiable) -> Bool {
        canEditItem(vaults: vaultsManager.getAllVaults(), item: item)
    }
}
