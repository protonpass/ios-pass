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
import XCTest
import Entities

final class ItemThumbnailableTests: XCTestCase {
    struct DummyItem: ItemThumbnailable {
        let title: String
        let url: String?
        let type: ItemContentType
    }

    func testAlwaysIconTypeForNotes() {
        // Given
        let item = DummyItem(title: .random(), url: nil, type: .note)

        // When
        let data = item.thumbnailData()

        // Then
        switch data {
        case let .icon(type):
            XCTAssertEqual(type, .note)
        default:
            XCTFail("Should be icon type")
        }
    }

    func testAlwaysIconTypeForAliases() {
        // Given
        let item = DummyItem(title: .random(), url: nil, type: .alias)

        // When
        let data = item.thumbnailData()

        // Then
        switch data {
        case let .icon(type):
            XCTAssertEqual(type, .alias)
        default:
            XCTFail("Should be alias type")
        }
    }

    func testInitialsTypeForLoginWithNoUrl() {
        // Given
        let title = "proton pass login item"
        let item = DummyItem(title: title, url: nil, type: .login)

        // When
        let data = item.thumbnailData()

        // Then
        switch data {
        case let .initials(type, initials):
            XCTAssertEqual(type, .login)
            XCTAssertEqual(initials, "PP")
        default:
            XCTFail("Should be initials type")
        }
    }

    func testFavIconTypeForLoginWithUrl() {
        // Given
        let givenTitle = "proton pass login item"
        let givenUrl = String.random()
        let item = DummyItem(title: givenTitle, url: givenUrl, type: .login)

        // When
        let data = item.thumbnailData()

        // Then
        switch data {
        case let .favIcon(type, url, initials):
            XCTAssertEqual(type, .login)
            XCTAssertEqual(url, givenUrl)
            XCTAssertEqual(initials, "PP")
        default:
            XCTFail("Should be fav icon type")
        }
    }
}
