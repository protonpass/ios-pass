//
// ItemContentProtobufIconTests.swift
// Proton Pass - Created on 29/09/2026.
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

import Entities
import Foundation
import Testing

@Suite(.tags(.entity))
struct ItemContentProtobufIconTests {
    let icon =
        "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=="

    func makeItem(customIcon: String?) -> ItemContentProtobuf {
        ItemContentProtobuf(name: "Item",
                            note: "Note",
                            itemUuid: "uuid",
                            data: .note,
                            customFields: [],
                            customIcon: customIcon)
    }

    @Test("Preserve icon through serialization")
    func preserveIcon() throws {
        let decoded = try ItemContentProtobuf(data: makeItem(customIcon: icon).data())

        #expect(decoded.metadata.hasIcon)
        #expect(decoded.customIcon == icon)
        #expect(decoded.name == "Item")
        #expect(decoded.uuid == "uuid")
    }

    @Test("Do not set icon for items without icon")
    func noIcon() throws {
        let decoded = try ItemContentProtobuf(data: makeItem(customIcon: nil).data())

        #expect(!decoded.metadata.hasIcon)
        #expect(decoded.customIcon == nil)
        #expect(decoded.name == "Item")
    }

    @Test("Produce identical bytes for items without icon and a cleared icon")
    func clearedIcon() throws {
        var cleared = makeItem(customIcon: icon)
        cleared.metadata.clearIcon()

        #expect(try cleared.data() == makeItem(customIcon: nil).data())
    }

    @Test("Encode icon as field 4 of Metadata")
    func wireFormat() throws {
        var metadata = ProtonPassItemV1_Metadata()
        metadata.icon = "A"
        // Tag (4 << 3 | length-delimited) = 0x22, length 1, "A"
        #expect(try metadata.serializedData() == Data([0x22, 0x01, 0x41]))
        #expect(try ProtonPassItemV1_Metadata(serializedBytes: Data([0x22, 0x01, 0x41])).icon == "A")
    }

    @Test("Map icon to and from ItemContent")
    func itemContent() throws {
        let item = Item(itemID: "item",
                        revision: 1,
                        contentFormatVersion: 1,
                        keyRotation: 1,
                        content: "",
                        itemKey: nil,
                        state: 1,
                        pinned: false,
                        pinTime: nil,
                        aliasEmail: nil,
                        createTime: 0,
                        modifyTime: 0,
                        lastUseTime: nil,
                        revisionTime: 0,
                        flags: 0,
                        shareCount: 0,
                        folderID: nil)
        let content = ItemContent(userId: "user",
                                  shareId: "share",
                                  item: item,
                                  contentProtobuf: makeItem(customIcon: icon),
                                  simpleLoginNote: nil)

        #expect(content.customIcon == icon)
        #expect(content.protobuf.customIcon == icon)
    }
}
