//
// LoginItemsViewModel.swift
// Proton Pass - Created on 27/02/2024.
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
//

import Client
import Combine
import Entities
import Foundation

enum LoginItemsViewModelState: Equatable {
    case idle
    case searching
    case searchResults([ItemSearchResult])
}

@MainActor
@Observable
final class LoginItemsViewModel {
    private(set) var state: LoginItemsViewModelState = .idle
    var query = ""

    let uiModels: [ItemUiModel]
    private let searchableItems: [SearchableItem]

    init(searchableItems: [SearchableItem], uiModels: [ItemUiModel]) {
        self.searchableItems = searchableItems
        self.uiModels = uiModels
    }

    /// Entirely main-actor isolated. No `MainActor.run`, no hop back.
    func search(term: String) async {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }

        state = .searching
        do {
            let results = try await Self.match(searchableItems, term: trimmed)
            try Task.checkCancellation()
            state = .searchResults(results)
        } catch is CancellationError {
            // Superseded — the newer call owns `state`. Don't clobber it.
        } catch {
            #if DEBUG
            print(error.localizedDescription)
            #endif
        }
    }

    /// The only part that runs off the main actor.
    @concurrent
    private static func match(_ items: [SearchableItem],
                              term: String) async throws -> [ItemSearchResult] {
        try await items.result(for: term)
    }
}
