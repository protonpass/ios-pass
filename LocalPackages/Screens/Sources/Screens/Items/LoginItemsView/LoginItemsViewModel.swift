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

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.searching, .searching),
             (.searchResults, .searchResults):
            true
        default:
            false
        }
    }
}

@MainActor
final class LoginItemsViewModel: ObservableObject {
    @Published private(set) var state: LoginItemsViewModelState = .idle
    @Published var query = ""

    private let searchableItems: [SearchableItem]
    let uiModels: [ItemUiModel]

    private var lastTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    init(searchableItems: [SearchableItem], uiModels: [ItemUiModel]) {
        self.searchableItems = searchableItems
        self.uiModels = uiModels
        setUp()
    }
}

private extension LoginItemsViewModel {
    func setUp() {
        $query
            .debounce(for: 0.4, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink { [weak self] term in
                guard let self else { return }
                doSearch(term: term)
            }
            .store(in: &cancellables)
    }

    func doSearch(term: String) {
        guard state != .searching else { return }
        guard !term.isEmpty else {
            state = .idle
            return
        }

        lastTask?.cancel()
        lastTask = Task { [weak self] in
            guard let self else { return }
            await searchAsync(term: term)
        }
    }

    nonisolated func searchAsync(term: String) async {
        await MainActor.run { [weak self] in
            guard let self else { return }
            state = .searching
        }

        do {
            let results = try await searchableItems.result(for: term)
            await MainActor.run { [weak self] in
                guard let self else { return }
                state = .searchResults(results)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
