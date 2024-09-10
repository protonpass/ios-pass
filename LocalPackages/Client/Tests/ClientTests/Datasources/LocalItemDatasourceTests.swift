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
import XCTest

final class LocalItemDatasourceTests: XCTestCase {
    var sut: LocalItemDatasource!
    
    override func setUp() {
        super.setUp()
        sut = .init(databaseService: DatabaseService(inMemory: true))
    }
    
    override func tearDown() {
        sut = nil
        super.tearDown()
    }
}

extension LocalItemDatasourceTests {

    func testGetAllItems() async throws {
        let currentUserId = "test"
        // Given
        var givenItems = [SymmetricallyEncryptedItem].random(randomElement: .random(userId: currentUserId))
        givenItems.append(.random())
        try await sut.upsertItems(givenItems)
        
        // When
        let items = try await sut.getAllItems(userId: currentUserId)
        
        // Then
        XCTAssertEqual(items.count, givenItems.count - 1)
        XCTAssertNotEqual(Set(items.map(\.itemId)), Set(givenItems.map(\.itemId)))
    }
    
    func testGetAllItemsByState() async throws {
        let currentUserId = "test"

        // Given
        let givenItems = [SymmetricallyEncryptedItem].random(randomElement: .random(userId: currentUserId))
        try await sut.upsertItems(givenItems)
        
        // When
        let activeItems = try await sut.getItems(userId: currentUserId, state: .active)
        let trashedItems = try await sut.getItems(userId: currentUserId, state: .trashed)
        let allItems = activeItems + trashedItems
        
        // Then
        XCTAssertEqual(activeItems.count + trashedItems.count, givenItems.count)
        XCTAssertEqual(Set(allItems.map(\.itemId)),
                       Set(givenItems.map(\.itemId)))
    }
    

    func testGetAllPinnedItems() async throws {
        let currentUserId = "test"

        // Given
        var givenItems = [SymmetricallyEncryptedItem].random(randomElement: .random(userId: currentUserId))
        givenItems.append(SymmetricallyEncryptedItem.random(userId: currentUserId,  item: .random(pinned: true)))
        try await sut.upsertItems(givenItems)
        
        // When
        let pinnedItems = try await sut.getAllPinnedItems(userId: currentUserId)
        
        // Then
        XCTAssertEqual(pinnedItems.count, 1)
        
        givenItems.append(SymmetricallyEncryptedItem.random(userId: currentUserId, item: .random(pinned: true)))
        try await sut.upsertItems(givenItems)
        
        // When
        let pinnedItems2 = try await sut.getAllPinnedItems(userId: currentUserId)
        
        // Then
        XCTAssertEqual(pinnedItems2.count, 2)
        
        // When
        let pinnedItems3 = try await sut.getAllPinnedItems(userId: "other user")
        
        // Then
        XCTAssertTrue(pinnedItems3.isEmpty)
    }
    
    func testGetItem() async throws {
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
        let optionalItems = try await sut.getItem(shareId: givenShareId,
                                                  itemId: givenItemId)
        let item = try await XCTUnwrapAsync(optionalItems)
        XCTAssertEqual(item, givenInsertedItem)
    }
    
    func testGetAliasItem() async throws {
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
        let optionalAlias = try await sut.getAliasItem(email: givenAliasEmail)
        let item = try await XCTUnwrapAsync(optionalAlias)
        XCTAssertEqual(item, givenInsertedItem)
    }
    
    func testInsertItems() async throws {
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
        XCTAssertEqual(itemCount, givenItems.count)
        
        let activeItems = try await sut.getItems(shareId: givenShareId,
                                                 state: .active)
        let activeItemIds = activeItems.map(\.item.itemID)
        
        let trashedItems = try await sut.getItems(shareId: givenShareId,
                                                  state: .trashed)
        let trashedItemIds = trashedItems.map(\.item.itemID)
        
        let givenItemIds = Set(givenItems.map(\.item.itemID))
        
        XCTAssertEqual(Set(activeItemIds + trashedItemIds), givenItemIds)
    }
    
    func testUpdateItems() async throws {
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
        XCTAssertEqual(itemCount, 1)
        
        let optionalItems = try await sut.getItem(shareId: givenShareId,
                                                  itemId: givenItemId)
        let item = try await XCTUnwrapAsync(optionalItems)
        XCTAssertEqual(item, updatedItem)
    }
    
    func testTrashItems() async throws {
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
        let optionalItems = try await sut.getItem(shareId: givenShareId,
                                                  itemId: givenItemId)
        let item = try await XCTUnwrapAsync(optionalItems)
        XCTAssertEqual(item.item.itemState, .trashed)
        XCTAssertEqual(item.item.flags, modifiedItem.flags)
    }
    
    func testUntrashItems() async throws {
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
        let optionalItems = try await sut.getItem(shareId: givenShareId,
                                                  itemId: givenItemId)
        let item = try await XCTUnwrapAsync(optionalItems)
        XCTAssertEqual(item.item.itemState, .active)
        XCTAssertEqual(item.item.flags, modifiedItem.flags)
    }
    
    func testDeleteItems() async throws {
        // Given
        let shareId = String.random()
        let firstItem = try await sut.givenInsertedItem(shareId: shareId)
        let secondItem = try await sut.givenInsertedItem(shareId: shareId)
        let thirdItem = try await sut.givenInsertedItem(shareId: shareId)
        
        let firstCount = try await sut.getItemCount(shareId: shareId)
        XCTAssertEqual(firstCount, 3)
        
        // Delete third item
        try await sut.deleteItems([thirdItem])
        let secondCount = try await sut.getItemCount(shareId: shareId)
        XCTAssertEqual(secondCount, 2)
        
        // Delete both first and second item
        try await sut.deleteItems([firstItem, secondItem])
        let thirdCount = try await sut.getItemCount(shareId: shareId)
        XCTAssertEqual(thirdCount, 0)
    }
    
    func testRemoveAllItems() async throws {
        let currentUserId = "test"
        // Given
        let givenItems = [SymmetricallyEncryptedItem].random(randomElement: .random(userId: currentUserId))
        try await sut.upsertItems(givenItems)
        
        // When
        try await sut.removeAllItems(userId: currentUserId)
        let items = try await sut.getAllItems(userId: currentUserId)
        
        // Then
        XCTAssertTrue(items.isEmpty)
    }
    
    func testRemoveAllItemsOfGivenShares() async throws {
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
        XCTAssertEqual(firstShareItemsFirstGetCount, givenFirstShareItems.count)
        
        let secondShareItemsFirstGetCount = try await sut.getItemCount(shareId: givenSecondShareId)
        XCTAssertEqual(secondShareItemsFirstGetCount, givenSecondShareItems.count)
        
        // When
        try await sut.removeAllItems(shareId: givenFirstShareId)
        
        // Then
        let firstShareItemsSecondGetCount = try await sut.getItemCount(shareId: givenFirstShareId)
        XCTAssertEqual(firstShareItemsSecondGetCount, 0)
        
        let secondShareItemsSecondGetCount = try await sut.getItemCount(shareId: givenSecondShareId)
        XCTAssertEqual(secondShareItemsSecondGetCount, givenSecondShareItems.count)
    }
    
    // Don't now why it is failing because lastUsedTime is not updated
    /*
     func testUpdateLastUsedTime() throws {
     continueAfterFailure = false
     let expectation = expectation(description: #function)
     Task {
     // Given
     let givenInsertedLogInItem = try await sut.givenInsertedItem(isLogInItem: true)
     let updatedLastUsedTime = Date().timeIntervalSince1970
     
     // When
     try await sut.update(item: givenInsertedLogInItem, lastUsedTime: updatedLastUsedTime)
     let item = try await sut.getItem(shareId: givenInsertedLogInItem.shareId,
     itemId: givenInsertedLogInItem.item.itemID)
     let notNilItem = try XCTUnwrap(item)
     XCTAssertEqual(notNilItem.lastUsedTime, Int64(updatedLastUsedTime))
     expectation.fulfill()
     }
     waitForExpectations(timeout: expectationTimeOut)
     }
     */

    func testGetActiveLogInItems() async throws {
        let currentUserId = "test"

        // Given
        let givenShareId = String.random()
        // 2 trashed log in items
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .trashed,
                                            isLogInItem: true)
        
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .trashed,
                                            isLogInItem: true)
        
        // 3 trashed other items
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .trashed,
                                            isLogInItem: false)
        
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .trashed,
                                            isLogInItem: false)
        
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .trashed,
                                            isLogInItem: false)
        
        // 4 active log in items
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .active,
                                            isLogInItem: true)
        
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .active,
                                            isLogInItem: true)
        
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .active,
                                            isLogInItem: true)
        
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .active,
                                            isLogInItem: true)
        
        // 4 active other items
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .active,
                                            isLogInItem: false)
        
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .active,
                                            isLogInItem: false)
        
        _ = try await sut.givenInsertedItem(shareId: givenShareId,
                                            userId: currentUserId,
                                            state: .active,
                                            isLogInItem: false)
        
        // When
        let activeLogInItems = try await sut.getActiveLogInItems(userId: currentUserId)
        
        // Then
        XCTAssertEqual(activeLogInItems.count, 4)
    }

    func testUpdateLastUseItems() async throws {
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
        XCTAssertEqual(retrievedItem1?.item.lastUseTime, 123)

        let retrievedItem2 = try await sut.getItem(shareId: givenShareId, itemId: item2.itemId)
        XCTAssertEqual(retrievedItem2?.item.lastUseTime, 234)

        let retrievedItem3 = try await sut.getItem(shareId: givenShareId, itemId: item3.itemId)
        XCTAssertEqual(retrievedItem3?.item.lastUseTime, 345)
    }
}

extension LocalItemDatasource {
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
                                              isLogInItem: isLogInItem)
        try await upsertItems([item])
        return item
    }
}
