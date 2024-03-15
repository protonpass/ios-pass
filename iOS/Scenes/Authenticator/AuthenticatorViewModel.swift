//
//
// AuthenticatorViewModel.swift
// Proton Pass - Created on 15/03/2024.
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

import Combine
import Entities
import Factory
import Foundation

@MainActor
final class AuthenticatorViewModel: ObservableObject, Sendable {
    @Published private(set) var displayedItems = [ItemContent]()
    private var items = [ItemContent]()
    @Published var searchText = ""

    private let getActiveLoginItems = resolve(\SharedUseCasesContainer.getActiveLoginItems)
    let totpManager = resolve(\ServiceContainer.totpManager)

    private var cancellables = Set<AnyCancellable>()

    init() {
        setUp()
    }

    func load() async {
        do {
            items = try await getActiveLoginItems()
                .filter { item in
                    guard let totpUri = item.loginItem?.totpUri,
                          !totpUri.isEmpty
                    else {
                        return false
                    }
                    return true
                }
            displayedItems = items
        } catch {
            print(error)
        }
    }
}

private extension AuthenticatorViewModel {
    func setUp() {
        $searchText
            .debounce(for: 0.4, scheduler: DispatchQueue.main)
            .removeDuplicates()
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] term in
                guard let self else { return }
                if term.isEmpty {
                    displayedItems = items
                } else {
                    displayedItems = items.filter { item in
                        guard let totpUri = item.loginItem?.totpUri.lowercased() else {
                            return false
                        }
                        print("totpUri: \(totpUri)")
                        print("term: \(term)")
                        print("totpUri contains: \(totpUri.contains(term.lowercased))")

                        guard let totpUri = item.loginItem?.totpUri,
                              totpUri.contains(term.lowercased)
                        else {
                            return false
                        }
                        return true
                    }
                }
            }
            .store(in: &cancellables)
    }
}
