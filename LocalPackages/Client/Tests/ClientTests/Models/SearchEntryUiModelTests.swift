//
// SearchEntryUiModelTests.swift
// Proton Pass - Created on 30/09/2026.
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

@testable import Client
import Entities
import EntitiesMocks
import Testing

struct SearchEntryUiModelTests {
    @Test("Recent search entries show the item's custom icon")
    func customIcon() {
        let icon = "data:image/png;base64,iVBORw0KGgo="
        let entry = SearchableItem(from: makeItemContent(customIcon: icon), allVaults: []).toSearchEntryUiModel

        #expect(entry.customIcon == icon)
        #expect(entry.thumbnailData() == .customIcon(type: .note, dataUri: icon))
    }

    @Test("Recent search entries without a custom icon keep the default thumbnail")
    func noCustomIcon() {
        let entry = SearchableItem(from: makeItemContent(customIcon: nil), allVaults: []).toSearchEntryUiModel

        #expect(entry.customIcon == nil)
        #expect(entry.thumbnailData() == .icon(type: .note))
    }
}

private func makeItemContent(customIcon: String?) -> ItemContent {
    ItemContent(shareId: "share",
                itemUuid: "uuid",
                userId: "user",
                item: .random(itemId: "item"),
                name: "Note",
                note: "",
                contentData: .note,
                customFields: [],
                simpleLoginNote: nil,
                customIcon: customIcon)
}
