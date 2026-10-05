//
// ItemTypeFilterOptionTests.swift
// Proton Pass - Created on 05/10/2026.
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
import Testing

@Suite(.tags(.entity))
struct ItemTypeFilterOptionTests {
    @Test(arguments: [ItemTypeFilterOption.all, .itemSharedWithMe, .itemSharedByMe]
        + ItemContentType.allCases.map(ItemTypeFilterOption.precise))
    func `every option survives a raw value round trip`(option: ItemTypeFilterOption) {
        #expect(ItemTypeFilterOption(rawValue: option.rawValue) == option)
    }

    @Test func `persisted raw values stay stable`() {
        #expect(ItemTypeFilterOption.all.rawValue == -1)
        #expect(ItemTypeFilterOption.itemSharedWithMe.rawValue == 300)
        #expect(ItemTypeFilterOption.itemSharedByMe.rawValue == 301)
        #expect(ItemContentType.allCases.allSatisfy { ItemTypeFilterOption.precise($0).rawValue == $0.rawValue })
    }

    @Test(arguments: [-1, 300, 301])
    func `reserved raw values do not collide with an item content type`(rawValue: Int) {
        #expect(ItemContentType(rawValue: rawValue) == nil)
    }

    @Test(arguments: [-2, 8, 299, 302])
    func `unknown raw values are rejected`(rawValue: Int) {
        #expect(ItemTypeFilterOption(rawValue: rawValue) == nil)
    }

    @Test func `only all is the default option`() {
        #expect(ItemTypeFilterOption.all.isDefault)
        #expect(!ItemTypeFilterOption.precise(.login).isDefault)
        #expect(!ItemTypeFilterOption.itemSharedWithMe.isDefault)
        #expect(!ItemTypeFilterOption.itemSharedByMe.isDefault)
    }
}
