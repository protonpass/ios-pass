//
//
// ItemHistoryViewModel.swift
// Proton Pass - Created on 09/01/2024.
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

import Entities
import Factory
import Foundation

@MainActor
final class ItemHistoryViewModel: ObservableObject, Sendable {
    @Published var itemStates = [ItemContent]()
    private let item: ItemContent

    private let getItemHistory = resolve(\UseCasesContainer.getItemHistory)

    init(item: ItemContent) {
        self.item = item
        setUp()
    }

    func loadItemHistory() async {
        do {
            itemStates = try await getItemHistory(shareId: item.shareId, itemId: item.itemId)
        } catch {
            print("Woot error for history: \(error)")
        }
    }
}

private extension ItemHistoryViewModel {
    func setUp() {}
}
