//  
// ArrayGroupAndBulkActionTests.swift
// Proton Pass - Created on 05/12/2023.
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
//

@testable import Core
import Testing

private struct Item {
    let shareId: String
    let itemId: String
}

@Suite(.tags(.utilities))
struct ArrayGroupAndBulkActionTests {
    @Test func `action is called once per share with only the selected items`() async throws {
        // Given
        let share0 = String.random()
        let share1 = String.random()
        let share2 = String.random()
        let share3 = String.random()

        let item0Share0 = Item(shareId: share0, itemId: String.random())
        let item1Share0 = Item(shareId: share0, itemId: String.random())

        let item0Share1 = Item(shareId: share1, itemId: String.random())
        let item1Share1 = Item(shareId: share1, itemId: String.random())

        let item0Share2 = Item(shareId: share2, itemId: String.random())
        let item1Share2 = Item(shareId: share2, itemId: String.random())

        let item0Share3 = Item(shareId: share3, itemId: String.random())
        let item1Share3 = Item(shareId: share3, itemId: String.random())

        let allItems = [item0Share0, item1Share0,
                        item0Share1, item1Share1,
                        item0Share2, item1Share2,
                        item0Share3, item1Share3]
        let selectedItems = [item1Share0,
                             item0Share1, item1Share1,
                             item1Share3]

        var actionedItemIds = [String: [String]]()

        // When
        try await allItems.groupAndBulkAction(
            by: \.shareId,
            shouldInclude: { item in
                selectedItems.contains(where: {
                    $0.shareId == item.shareId && $0.itemId == item.itemId
                })
            }, action: { items, shareId in
                actionedItemIds[shareId, default: []] += items.map(\.itemId)
            })

        // Then
        #expect(actionedItemIds == [
            share0: [item1Share0.itemId],
            share1: [item0Share1.itemId, item1Share1.itemId],
            share3: [item1Share3.itemId]
        ])
    }
}
