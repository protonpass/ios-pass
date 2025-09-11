//
// LocalItemDatasourceTests.swift
// Proton Pass - Created on 20/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import Foundation
import Testing

@Suite(.tags(.localDatasource))
struct LocalItemDatasourceTests {
    let sut = LocalItemDatasource(databaseService: DatabaseService(inMemory: true))
}

extension LocalItemDatasourceTests {
    @Test("Get all items by user")
    func getAllItems() async throws {
        let currentUserId = "test"
        // Given
        var givenItems = [SymmetricallyEncryptedItem].random(randomElement: .random(userId: currentUserId))
        givenItems.append(.random())
        try await sut.upsertItems(givenItems)
        
        // When
        let items = try await sut.getAllItems(userId: currentUserId)
        
        // Then
        #expect(items.count == givenItems.count - 1)
        #expect(Set(items.map(\.itemId)) != Set(givenItems.map(\.itemId)))
    }

    @Test("Get all itesm by state by user")
    func getAllItemsByState() async throws {
        let currentUserId = "test"

        // Given
        let givenItems = [SymmetricallyEncryptedItem].random(randomElement: .random(userId: currentUserId))
        try await sut.upsertItems(givenItems)
        
        // When
        let activeItems = try await sut.getItems(userId: currentUserId, state: .active)
        let trashedItems = try await sut.getItems(userId: currentUserId, state: .trashed)
        let allItems = activeItems + trashedItems
        
        // Then
        #expect(activeItems.count + trashedItems.count == givenItems.count)
        #expect(Set(allItems.map(\.itemId)) == Set(givenItems.map(\.itemId)))
    }

    @Test("Get all pinned items by user")
    func getAllPinnedItems() async throws {
        let currentUserId = "test"

        // Given
        var givenItems = [SymmetricallyEncryptedItem].random(randomElement:
                .random(userId: currentUserId,
                        item: .random(state: .trashed, pinned: false)))
        givenItems.append(SymmetricallyEncryptedItem.random(userId: currentUserId,
                                                            item: .random(state: .active,
                                                                          pinned: true)))
        try await sut.upsertItems(givenItems)

        // When
        let pinnedItems = try await sut.getAllPinnedItems(userId: currentUserId)
        
        // Then
        #expect(pinnedItems.count == 1)

        givenItems.append(SymmetricallyEncryptedItem.random(userId: currentUserId,
                                                            item: .random(state: .active,
                                                                          pinned: true)))
        try await sut.upsertItems(givenItems)
        
        // When
        let pinnedItems2 = try await sut.getAllPinnedItems(userId: currentUserId)
        
        // Then
        #expect(pinnedItems2.count == 2)
        
        // When
        let pinnedItems3 = try await sut.getAllPinnedItems(userId: "other user")
        
        // Then
        #expect(pinnedItems3.isEmpty)
    }

    @Test("Get specific item")
    func getItem() async throws {
        // Given
        let givenShareId = String.random()
        let givenItemId = String.random()
        let givenInsertedItem = try await sut.givenInsertedItem(itemId: givenItemId,
                                                                shareId: givenShareId)
        
        // When
        for _ in 0...10 {
            try await sut.upsertItems(.random(randomElement: .random()))
        }

        // Then
        let item = try #require(try await sut.getItem(shareId: givenShareId,
                                                      itemId: givenItemId))
        #expect(item == givenInsertedItem)
    }

    @Test("Get alias item")
    func getAliasItem() async throws {
        // Given
        let givenShareId = String.random()
        let givenItemId = String.random()
        let givenAliasEmail = String.random()
        let givenInsertedItem = try await sut.givenInsertedItem(itemId: givenItemId,
                                                                shareId: givenShareId,
                                                                aliasEmail: givenAliasEmail)
        
        // When
        for _ in 0...10 {
            try await sut.upsertItems(.random(randomElement: .random()))
        }

        // Then
        let item = try #require(try await sut.getAliasItem(email: givenAliasEmail,
                                                           shareId: givenShareId))
        #expect(item == givenInsertedItem)
    }

    @Test("Insert items")
    func insertItems() async throws {
        // Given
        let givenShareId = String.random()
        
        let firstItems =
        [SymmetricallyEncryptedItem].random(randomElement: .random(shareId: givenShareId))
        
        let secondItems =
        [SymmetricallyEncryptedItem].random(randomElement: .random(shareId: givenShareId))
        
        let thirdItems =
        [SymmetricallyEncryptedItem].random(randomElement: .random(shareId: givenShareId))
        
        let givenItems = firstItems + secondItems + thirdItems
        
        // When
        try await sut.upsertItems(firstItems)
        try await sut.upsertItems(secondItems)
        try await sut.upsertItems(thirdItems)
        
        // Then
        let itemCount = try await sut.getItemCount(shareId: givenShareId)
        #expect(itemCount == givenItems.count)

        let activeItems = try await sut.getItems(shareId: givenShareId,
                                                 state: .active)
        let activeItemIds = activeItems.map(\.item.itemID)
        
        let trashedItems = try await sut.getItems(shareId: givenShareId,
                                                  state: .trashed)
        let trashedItemIds = trashedItems.map(\.item.itemID)
        
        let givenItemIds = Set(givenItems.map(\.item.itemID))

        #expect(Set(activeItemIds + trashedItemIds) == givenItemIds)
    }

    @Test("Update items")
    func updateItems() async throws {
        // Given
        let givenItemId = String.random()
        let givenShareId = String.random()
        let givenItem = try await sut.givenInsertedItem(itemId: givenItemId,
                                                        shareId: givenShareId)
        let updatedItemRevision = Item.random(itemId: givenItemId)
        let updatedItem = SymmetricallyEncryptedItem.random(shareId: givenShareId,
                                                            item: updatedItemRevision,
                                                            isLogInItem: givenItem.isLogInItem)

        // When
        try await sut.upsertItems([updatedItem])
        
        // Then
        let itemCount = try await sut.getItemCount(shareId: givenShareId)
        #expect(itemCount == 1)

        let item = try #require(try await sut.getItem(shareId: givenShareId,
                                                      itemId: givenItemId))
        #expect(item == updatedItem)
    }

    @Test("Trash items")
    func trashItems() async throws {
        // Given
        let givenItemId = String.random()
        let givenShareId = String.random()
        let insertedItem = try await sut.givenInsertedItem(itemId: givenItemId,
                                                           shareId: givenShareId,
                                                           state: .active)

        // When
        let modifiedItem = ModifiedItem(itemID: insertedItem.item.itemID,
                                        revision: insertedItem.item.revision,
                                        state: ItemState.trashed.rawValue,
                                        modifyTime: insertedItem.item.modifyTime,
                                        revisionTime: insertedItem.item.revisionTime,
                                        flags: .random(in: 1...100))
        try await sut.upsertItems([insertedItem], modifiedItems: [modifiedItem])

        // Then
        let item = try #require(try await sut.getItem(shareId: givenShareId,
                                                      itemId: givenItemId))
        #expect(item.item.itemState == .trashed)
        #expect(item.item.flags == modifiedItem.flags)
    }

    @Test("Untrash items")
    func untrashItems() async throws {
        // Given
        let givenItemId = String.random()
        let givenShareId = String.random()
        let insertedItem = try await sut.givenInsertedItem(itemId: givenItemId,
                                                           shareId: givenShareId,
                                                           state: .trashed)
        
        // When
        let modifiedItem = ModifiedItem(itemID: insertedItem.item.itemID,
                                        revision: insertedItem.item.revision,
                                        state: ItemState.active.rawValue,
                                        modifyTime: insertedItem.item.modifyTime,
                                        revisionTime: insertedItem.item.revisionTime,
                                        flags: .random(in: 1...100))
        try await sut.upsertItems([insertedItem], modifiedItems: [modifiedItem])
        
        // Then
        let item = try #require(try await sut.getItem(shareId: givenShareId, itemId: givenItemId))
        #expect(item.item.itemState == .active)
        #expect(item.item.flags == modifiedItem.flags)
    }

    @Test("Delete items")
    func deleteItems() async throws {
        // Given
        let shareId = String.random()
        let firstItem = try await sut.givenInsertedItem(shareId: shareId)
        let secondItem = try await sut.givenInsertedItem(shareId: shareId)
        let thirdItem = try await sut.givenInsertedItem(shareId: shareId)
        
        let firstCount = try await sut.getItemCount(shareId: shareId)
        #expect(firstCount == 3)

        // Delete third item
        try await sut.deleteItems([thirdItem])
        let secondCount = try await sut.getItemCount(shareId: shareId)
        #expect(secondCount == 2)

        // Delete both first and second item
        try await sut.deleteItems([firstItem, secondItem])
        let thirdCount = try await sut.getItemCount(shareId: shareId)
        #expect(thirdCount == 0)
    }

    @Test("Remove all items by user")
    func removeAllItems() async throws {
        let currentUserId = "test"
        // Given
        let givenItems = [SymmetricallyEncryptedItem].random(randomElement: .random(userId: currentUserId))
        try await sut.upsertItems(givenItems)
        
        // When
        try await sut.removeAllItems(userId: currentUserId)
        let items = try await sut.getAllItems(userId: currentUserId)
        
        // Then
        #expect(items.isEmpty)
    }

    @Test("Remove all items by shares")
    func removeAllItemsOfGivenShares() async throws {
        // Given
        let givenFirstShareId = String.random()
        let givenFirstShareItems =
        [SymmetricallyEncryptedItem].random(randomElement: .random(shareId: givenFirstShareId))
        
        let givenSecondShareId = String.random()
        let givenSecondShareItems =
        [SymmetricallyEncryptedItem].random(randomElement: .random(shareId: givenSecondShareId))
        
        // When
        try await sut.upsertItems(givenFirstShareItems)
        try await sut.upsertItems(givenSecondShareItems)
        
        // Then
        let firstShareItemsFirstGetCount = try await sut.getItemCount(shareId: givenFirstShareId)
        #expect(firstShareItemsFirstGetCount == givenFirstShareItems.count)

        let secondShareItemsFirstGetCount = try await sut.getItemCount(shareId: givenSecondShareId)
        #expect(secondShareItemsFirstGetCount == givenSecondShareItems.count)

        // When
        try await sut.removeAllItems(shareId: givenFirstShareId)
        
        // Then
        let firstShareItemsSecondGetCount = try await sut.getItemCount(shareId: givenFirstShareId)
        #expect(firstShareItemsSecondGetCount == 0)

        let secondShareItemsSecondGetCount = try await sut.getItemCount(shareId: givenSecondShareId)
        #expect(secondShareItemsSecondGetCount == givenSecondShareItems.count)
    }

    @Test("Get active login items by user")
    func getActiveLogInItems() async throws {
        let currentUserId = "test"

        // Given
        let givenShareId = String.random()
        // 2 trashed log in items
        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .trashed,
                                        isLogInItem: true)

        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .trashed,
                                        isLogInItem: true)

        // 3 trashed other items
        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .trashed,
                                        isLogInItem: false)

        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .trashed,
                                        isLogInItem: false)

        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .trashed,
                                        isLogInItem: false)

        // 4 active log in items
        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .active,
                                        isLogInItem: true)

        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .active,
                                        isLogInItem: true)

        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .active,
                                        isLogInItem: true)

        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .active,
                                        isLogInItem: true)

        // 4 active other items
        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .active,
                                        isLogInItem: false)

        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .active,
                                        isLogInItem: false)

        try await sut.givenInsertedItem(shareId: givenShareId,
                                        userId: currentUserId,
                                        state: .active,
                                        isLogInItem: false)

        // When
        let activeLogInItems = try await sut.getActiveLogInItems(userId: currentUserId)
        
        // Then
        #expect(activeLogInItems.count == 4)
    }

    @Test("Update last use items")
    func updateLastUseItems() async throws {
        // Given
        let givenShareId = String.random()
        let item1 = try await sut.givenInsertedItem(shareId: givenShareId)
        let item2 = try await sut.givenInsertedItem(shareId: givenShareId)
        let item3 = try await sut.givenInsertedItem(shareId: givenShareId)

        // When
        let updatedItem1 = LastUseItem(itemID: item1.itemId, lastUseTime: 123)
        let updatedItem2 = LastUseItem(itemID: item2.itemId, lastUseTime: 234)
        let updatedItem3 = LastUseItem(itemID: item3.itemId, lastUseTime: 345)
        try await sut.update(lastUseItems: [updatedItem1, updatedItem2, updatedItem3],
                             shareId: givenShareId)

        // Then
        let retrievedItem1 = try await sut.getItem(shareId: givenShareId, itemId: item1.itemId)
        #expect(retrievedItem1?.item.lastUseTime == 123)

        let retrievedItem2 = try await sut.getItem(shareId: givenShareId, itemId: item2.itemId)
        #expect(retrievedItem2?.item.lastUseTime == 234)

        let retrievedItem3 = try await sut.getItem(shareId: givenShareId, itemId: item3.itemId)
        #expect(retrievedItem3?.item.lastUseTime == 345)
    }

    @Test("Get alias count")
    func getAliasCount() async throws {
        // Given
        let user1 = String.random()
        try await sut.givenInsertedItem(userId: user1, aliasEmail: .random())
        try await sut.givenInsertedItem(userId: user1)
        try await sut.givenInsertedItem(userId: user1, aliasEmail: .random())
        try await sut.givenInsertedItem(userId: user1)

        let user2 = String.random()
        try await sut.givenInsertedItem(userId: user2)
        try await sut.givenInsertedItem(userId: user2)

        // When
        let aliasCount1 = try await sut.getAliasCount(userId: user1)
        let aliasCount2 = try await sut.getAliasCount(userId: user2)

        // Then
        #expect(aliasCount1 == 2)
        #expect(aliasCount2 == 0)
    }

    @Test("Get unsynced SimpleLogin note aliases")
    func getUnsyncedSimpleLoginNoteAliases() async throws {
        // Given
        let userId = String.random()
        try await sut.givenInsertedItem(userId: userId)
        let givenAlias1 = try await sut.givenInsertedItem(userId: userId,
                                                          aliasEmail: .random(),
                                                          modifyTime: 12)
        try await sut.givenInsertedItem(userId: userId)
        let givenAlias2 = try await sut.givenInsertedItem(userId: userId,
                                                          aliasEmail: .random(),
                                                          modifyTime: 8)
        try await sut.givenInsertedItem(userId: userId)
        try await sut.givenInsertedItem(userId: userId)
        let givenAlias3 = try await sut.givenInsertedItem(userId: userId,
                                                          aliasEmail: .random(),
                                                          modifyTime: 30)
        let givenAlias4 = try await sut.givenInsertedItem(userId: userId,
                                                          aliasEmail: .random(),
                                                          modifyTime: 46)

        // When
        let aliasCount = try await sut.getAliasCount(userId: userId)

        // Then
        #expect(aliasCount == 4)

        // When
        let unsyncedAliases = try await sut.getUnsyncedSimpleLoginNoteAliases(userId: userId,
                                                                              pageSize: 3)

        // Then
        #expect(unsyncedAliases.count == 3)
        #expect(unsyncedAliases[0] == givenAlias4)
        #expect(unsyncedAliases[1] == givenAlias3)
        #expect(unsyncedAliases[2] == givenAlias1)
        #expect(!unsyncedAliases.contains(givenAlias2))
    }

    @Test("Update cached alias info")
    func updateCachedAliasInfo() async throws {
        // Given
        let userId = String.random()
        let givenAlias1 = try await sut.givenInsertedItem(userId: userId, aliasEmail: .random())
        let givenAlias2 = try await sut.givenInsertedItem(userId: userId, aliasEmail: .random())

        let alias1Info = SymmetricallyEncryptedAlias(email: givenAlias1.item.aliasEmail ?? "",
                                                     encryptedNote: .random())

        let alias2Info = SymmetricallyEncryptedAlias(email: givenAlias2.item.aliasEmail ?? "",
                                                     encryptedNote: .random())

        // When
        try await sut.updateCachedAliasInfo(items: [givenAlias1, givenAlias2],
                                            aliases: [alias1Info, alias2Info])

        // Then
        let aliases = try await sut.getAllItems(userId: userId)
        #expect(aliases.count == 2)

        let alias1 = try #require(aliases.first(where: { $0.item.aliasEmail == givenAlias1.item.aliasEmail }))
        #expect(alias1.encryptedSimpleLoginNote == alias1Info.encryptedNote)
        #expect(alias1.simpleLoginNoteSynced)

        let alias2 = try #require(aliases.first(where: { $0.item.aliasEmail == givenAlias2.item.aliasEmail }))
        #expect(alias2.encryptedSimpleLoginNote == alias2Info.encryptedNote)
        #expect(alias2.simpleLoginNoteSynced)
    }
}

private extension LocalItemDatasource {
    @discardableResult
    func givenInsertedItem(itemId: String? = nil,
                           shareId: String? = nil,
                           userId: String? = nil,
                           state: ItemState? = nil,
                           encryptedContent: String? = nil,
                           aliasEmail: String? = nil,
                           modifyTime: Int64 = .random(in: 1_234_567...1_987_654),
                           lastUsedItem: Int64 = .random(in: 1_234_567...1_987_654),
                           isLogInItem: Bool = .random())
    async throws -> SymmetricallyEncryptedItem {
        let shareId = shareId ?? .random()
        let itemRevision = Item.random(itemId: itemId ?? .random(),
                                               state: state,
                                               aliasEmail: aliasEmail,
                                               modifyTime: modifyTime)
        let encryptedContent = encryptedContent ?? .random()
        let item = SymmetricallyEncryptedItem(shareId: shareId, 
                                              userId: userId ?? .random(),
                                              item: itemRevision,
                                              encryptedContent: encryptedContent,
                                              isLogInItem: isLogInItem,
                                              encryptedSimpleLoginNote: nil,
                                              simpleLoginNoteSynced: false)
        try await upsertItems([item])
        return item
    }
}
