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
import EntitiesMocks
import Testing

@Suite(.tags(.manager))
struct ShareIdToUserManagerTests {
    private struct Item: ItemIdentifiable {
        var folderId: String?
        
        let shareId: String
        let itemId: String

        static func random() -> Item {
            .init(shareId: .random(), itemId: .random())
        }
    }

    @Test func `user is only found for items whose share has been indexed`() throws {
        // Given
        let vault = Share.random()
        let item1 = Item.random()
        let user = UserUiModel.random()

        // When
        let sut = ShareIdToUserManager(users: [user])

        // Then
        #expect(throws: PassError.userManager(.noUserFound(shareId: item1.shareId, itemId: item1.itemId))) {
            try sut.getUser(for: item1)
        }

        // When
        let item2 = Item(shareId: vault.shareId, itemId: .random())
        sut.index(vaults: [vault], userId: user.id)

        // Then
        #expect(try sut.getUser(for: item2) == user)
    }
}
