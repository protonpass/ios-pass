//
// ItemThumbnailableTests.swift
// Proton Pass - Created on 14/04/2023.
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

@testable import Client
import Entities
import Testing

@Suite(.tags(.models))
struct ItemThumbnailableTests {
    struct DummyItem: ItemThumbnailable {
        let title: String
        let url: String?
        let type: ItemContentType
    }

    @Test(arguments: [ItemContentType.note, .alias])
    func `notes and aliases always use the icon thumbnail`(type: ItemContentType) {
        let item = DummyItem(title: .random(), url: nil, type: type)

        #expect(item.thumbnailData() == .icon(type: type))
    }

    @Test func `a login without url uses the initials thumbnail`() {
        let item = DummyItem(title: "proton pass login item", url: nil, type: .login)

        #expect(item.thumbnailData() == .initials(type: .login, initials: "PP"))
    }

    @Test func `a login with url uses the fav icon thumbnail`() {
        let givenUrl = String.random()
        let item = DummyItem(title: "proton pass login item", url: givenUrl, type: .login)

        #expect(item.thumbnailData() == .favIcon(type: .login, url: givenUrl, initials: "PP"))
    }
}
