//
// ItemIdentifiableTests.swift
// Proton Pass - Created on 11/09/2026.
// Copyright (c) 2026 Proton Technologies AG
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

@testable import Entities
import EntitiesMocks
import Testing

struct ItemIdentifiableTests {
    let shareId = "share-1"
    let otherShareId = "share-2"

    /// root -> item-A, F1
    /// F1   -> item-B, F2
    /// F2   -> item-C
    /// plus item-X in another share
    private var items: [ItemUiModel] {
        [
            ItemUiModel.mock(itemId: "item-A", shareId: shareId),
            ItemUiModel.mock(itemId: "item-B", shareId: shareId, folderId: "folder-F1"),
            ItemUiModel.mock(itemId: "item-C", shareId: shareId, folderId: "folder-F2"),
            ItemUiModel.mock(itemId: "item-X", shareId: otherShareId)
        ]
    }

    @Test
    func `scoped with nil containerIds keeps the whole share at any depth`() {
        let result = items.scoped(toShare: shareId, containerIds: nil)

        #expect(result.map(\.itemId) == ["item-A", "item-B", "item-C"])
    }

    @Test
    func `scoped never leaks items from another share`() {
        #expect(items.scoped(toShare: shareId, containerIds: nil).allSatisfy { $0.shareId == shareId })
        #expect(items.scoped(toShare: otherShareId, containerIds: nil).map(\.itemId) == ["item-X"])
    }

    @Test
    func `scoped to a folder subtree includes descendants but not the root`() {
        let result = items.scoped(toShare: shareId, containerIds: ["folder-F1", "folder-F2"])

        #expect(result.map(\.itemId) == ["item-B", "item-C"])
    }

    @Test
    func `scoped to a single folder excludes its descendants`() {
        let result = items.scoped(toShare: shareId, containerIds: ["folder-F1"])

        #expect(result.map(\.itemId) == ["item-B"])
    }

    @Test
    func `scoped to the share id matches only root items`() {
        let result = items.scoped(toShare: shareId, containerIds: [shareId])

        #expect(result.map(\.itemId) == ["item-A"])
    }

    @Test
    func `scoped to an empty container set matches nothing`() {
        #expect(items.scoped(toShare: shareId, containerIds: []).isEmpty)
    }
}
