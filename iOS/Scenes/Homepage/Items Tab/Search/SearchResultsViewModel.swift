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
import FactoryKit
import Macro
import SwiftUI

enum VaultSearchSelection: Equatable {
    case current
    case all
}

@MainActor
final class SearchResultsViewModel: ObservableObject {
    @Published var itemToBePermanentlyDeleted: (any ItemTypeIdentifiable)?
    private let appContentManager = resolve(\SharedServiceContainer.appContentManager)
    private let canEditItem = resolve(\SharedUseCasesContainer.canEditItem)

    private var vaultSearchSelection: VaultSearchSelection = .current

    let itemContextMenuHandler: ItemContextMenuHandler

    var itemCount: ItemCount {
        guard let all = fullResults.all else {
            return fullResults.current.itemCount
        }
        return vaultSearchSelection == .current ? fullResults.current.itemCount : all.itemCount
    }

    var results: any SearchResults {
        guard let all = fullResults.all else {
            return fullResults.current.searchResults
        }
        return vaultSearchSelection == .current ? fullResults.current.searchResults : all.searchResults
    }

    let mode: SearchMode?
    let fullResults: SearchDataDisplayContainer

    var isTrash: Bool {
        mode?.vaultSelection == .trash
    }

    var currentSelectionTitle: String {
        switch mode?.vaultSelection {
        case .sharedWithMe:
            #localized("Shared with me")
        case .sharedByMe:
            #localized("Shared by me")
        case .trash:
            #localized("Trash")
        default:
            #localized("Current vault")
        }
    }

    init(itemContextMenuHandler: ItemContextMenuHandler,
         results: SearchDataDisplayContainer,
         vaultSearchSelection: VaultSearchSelection,
         mode: SearchMode?) {
        self.itemContextMenuHandler = itemContextMenuHandler
        fullResults = results
        self.vaultSearchSelection = vaultSearchSelection
        self.mode = mode
    }
}

// MARK: Public APIs

extension SearchResultsViewModel {
    func disableAlias() {
        guard let itemToBePermanentlyDeleted else { return }
        itemContextMenuHandler.disableAlias(itemToBePermanentlyDeleted)
    }

    func permanentlyDelete() {
        guard let itemToBePermanentlyDeleted else { return }
        itemContextMenuHandler.deletePermanently(itemToBePermanentlyDeleted)
    }

    func isEditable(_ item: any ItemIdentifiable) -> Bool {
        canEditItem(vaults: appContentManager.getAllShares(), item: item)
    }
}
