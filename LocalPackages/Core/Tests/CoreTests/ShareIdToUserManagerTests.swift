//
// ShareIdToUserManagerTests.swift
// Proton Pass - Created on 10/09/2024.
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

@testable import Core
import Entities
import XCTest

final class ShareIdToUserManagerTests: XCTestCase {
    var sut: ShareIdToUserManager!

    private struct Item: ItemIdentifiable {
        let shareId: String
        let itemId: String

        static func random() -> Item {
            .init(shareId: .random(), itemId: .random())
        }
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension ShareIdToUserManagerTests {
    func testGetUserWithFailure() {
        // Given
        sut = .init(users: [.random()])
        let item = Item.random()
        XCTAssertThrowsError(try sut.getUser(for: item)) { error in
            if let passError = error as? PassError {
                switch passError {
                case let .userManager(reason):
                    if case let .noUserFound(shareId, itemId) = reason,
                       shareId == item.shareId,
                       itemId == item.itemId {
                        break
                    }
                    fallthrough
                default:
                    XCTFail("Unexpected error \(error)")
                }
            }
        }
    }

    func testGetUserWithSuccess() throws {
        // Given
        let vault = Vault.random()
        let item = Item(shareId: vault.shareId, itemId: .random())
        let user = PassUser.random()
        sut = .init(users: [user])
        sut.index(vaults: [vault], userId: user.id)

        // When
        let firstGet = try sut.getUser(for: item)

        // Then
        XCTAssertFalse(firstGet.cached)
        XCTAssertEqual(firstGet.object, user)

        // When
        let secondGet = try sut.getUser(for: item)

        // Then
        XCTAssertTrue(secondGet.cached)
        XCTAssertEqual(secondGet.object, user)
    }
}
