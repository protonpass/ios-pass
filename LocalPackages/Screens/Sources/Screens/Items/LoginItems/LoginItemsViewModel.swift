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

    func search(term: String, in items: [SearchableItem]) async {
        let trimmed = term.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }

        state = .searching
        do {
            let results = try await items.result(for: trimmed)
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
}
