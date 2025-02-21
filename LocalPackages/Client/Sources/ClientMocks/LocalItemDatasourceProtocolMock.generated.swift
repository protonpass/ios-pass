// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT
// Proton Pass.
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

import Client
import CoreData
import Entities

public final class LocalItemDatasourceProtocolMock: @unchecked Sendable, LocalItemDatasourceProtocol {

    public init() {}

    // MARK: - getAllItems
    public var getAllItemsUserIdThrowableError1: Error?
    public var closureGetAllItems: () -> () = {}
    public var invokedGetAllItemsfunction = false
    public var invokedGetAllItemsCount = 0
    public var invokedGetAllItemsParameters: (userId: String, Void)?
    public var invokedGetAllItemsParametersList = [(userId: String, Void)]()
    public var stubbedGetAllItemsResult: [SymmetricallyEncryptedItem]!

    public func getAllItems(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetAllItemsfunction = true
        invokedGetAllItemsCount += 1
        invokedGetAllItemsParameters = (userId, ())
        invokedGetAllItemsParametersList.append((userId, ()))
        if let error = getAllItemsUserIdThrowableError1 {
            throw error
        }
        closureGetAllItems()
        return stubbedGetAllItemsResult
    }
    // MARK: - getAllPinnedItems
    public var getAllPinnedItemsUserIdThrowableError2: Error?
    public var closureGetAllPinnedItems: () -> () = {}
    public var invokedGetAllPinnedItemsfunction = false
    public var invokedGetAllPinnedItemsCount = 0
    public var invokedGetAllPinnedItemsParameters: (userId: String, Void)?
    public var invokedGetAllPinnedItemsParametersList = [(userId: String, Void)]()
    public var stubbedGetAllPinnedItemsResult: [SymmetricallyEncryptedItem]!

    public func getAllPinnedItems(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetAllPinnedItemsfunction = true
        invokedGetAllPinnedItemsCount += 1
        invokedGetAllPinnedItemsParameters = (userId, ())
        invokedGetAllPinnedItemsParametersList.append((userId, ()))
        if let error = getAllPinnedItemsUserIdThrowableError2 {
            throw error
        }
        closureGetAllPinnedItems()
        return stubbedGetAllPinnedItemsResult
    }
    // MARK: - getItemsUserIdState
    public var getItemsUserIdStateThrowableError3: Error?
    public var closureGetItemsUserIdStateAsync3: () -> () = {}
    public var invokedGetItemsUserIdStateAsync3 = false
    public var invokedGetItemsUserIdStateAsyncCount3 = 0
    public var invokedGetItemsUserIdStateAsyncParameters3: (userId: String, state: ItemState)?
    public var invokedGetItemsUserIdStateAsyncParametersList3 = [(userId: String, state: ItemState)]()
    public var stubbedGetItemsUserIdStateAsyncResult3: [SymmetricallyEncryptedItem]!

    public func getItems(userId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsUserIdStateAsync3 = true
        invokedGetItemsUserIdStateAsyncCount3 += 1
        invokedGetItemsUserIdStateAsyncParameters3 = (userId, state)
        invokedGetItemsUserIdStateAsyncParametersList3.append((userId, state))
        if let error = getItemsUserIdStateThrowableError3 {
            throw error
        }
        closureGetItemsUserIdStateAsync3()
        return stubbedGetItemsUserIdStateAsyncResult3
    }
    // MARK: - getItemsShareIdState
    public var getItemsShareIdStateThrowableError4: Error?
    public var closureGetItemsShareIdStateAsync4: () -> () = {}
    public var invokedGetItemsShareIdStateAsync4 = false
    public var invokedGetItemsShareIdStateAsyncCount4 = 0
    public var invokedGetItemsShareIdStateAsyncParameters4: (shareId: String, state: ItemState)?
    public var invokedGetItemsShareIdStateAsyncParametersList4 = [(shareId: String, state: ItemState)]()
    public var stubbedGetItemsShareIdStateAsyncResult4: [SymmetricallyEncryptedItem]!

    public func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsShareIdStateAsync4 = true
        invokedGetItemsShareIdStateAsyncCount4 += 1
        invokedGetItemsShareIdStateAsyncParameters4 = (shareId, state)
        invokedGetItemsShareIdStateAsyncParametersList4.append((shareId, state))
        if let error = getItemsShareIdStateThrowableError4 {
            throw error
        }
        closureGetItemsShareIdStateAsync4()
        return stubbedGetItemsShareIdStateAsyncResult4
    }
    // MARK: - getItem
    public var getItemShareIdItemIdThrowableError5: Error?
    public var closureGetItem: () -> () = {}
    public var invokedGetItemfunction = false
    public var invokedGetItemCount = 0
    public var invokedGetItemParameters: (shareId: String, itemId: String)?
    public var invokedGetItemParametersList = [(shareId: String, itemId: String)]()
    public var stubbedGetItemResult: SymmetricallyEncryptedItem?

    public func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem? {
        invokedGetItemfunction = true
        invokedGetItemCount += 1
        invokedGetItemParameters = (shareId, itemId)
        invokedGetItemParametersList.append((shareId, itemId))
        if let error = getItemShareIdItemIdThrowableError5 {
            throw error
        }
        closureGetItem()
        return stubbedGetItemResult
    }
    // MARK: - getAliasItem
    public var getAliasItemEmailShareIdThrowableError6: Error?
    public var closureGetAliasItem: () -> () = {}
    public var invokedGetAliasItemfunction = false
    public var invokedGetAliasItemCount = 0
    public var invokedGetAliasItemParameters: (email: String, shareId: String)?
    public var invokedGetAliasItemParametersList = [(email: String, shareId: String)]()
    public var stubbedGetAliasItemResult: SymmetricallyEncryptedItem?

    public func getAliasItem(email: String, shareId: String) async throws -> SymmetricallyEncryptedItem? {
        invokedGetAliasItemfunction = true
        invokedGetAliasItemCount += 1
        invokedGetAliasItemParameters = (email, shareId)
        invokedGetAliasItemParametersList.append((email, shareId))
        if let error = getAliasItemEmailShareIdThrowableError6 {
            throw error
        }
        closureGetAliasItem()
        return stubbedGetAliasItemResult
    }
    // MARK: - getItemCount
    public var getItemCountShareIdThrowableError7: Error?
    public var closureGetItemCount: () -> () = {}
    public var invokedGetItemCountfunction = false
    public var invokedGetItemCountCount = 0
    public var invokedGetItemCountParameters: (shareId: String, Void)?
    public var invokedGetItemCountParametersList = [(shareId: String, Void)]()
    public var stubbedGetItemCountResult: Int!

    public func getItemCount(shareId: String) async throws -> Int {
        invokedGetItemCountfunction = true
        invokedGetItemCountCount += 1
        invokedGetItemCountParameters = (shareId, ())
        invokedGetItemCountParametersList.append((shareId, ()))
        if let error = getItemCountShareIdThrowableError7 {
            throw error
        }
        closureGetItemCount()
        return stubbedGetItemCountResult
    }
    // MARK: - getAliasCount
    public var getAliasCountUserIdThrowableError8: Error?
    public var closureGetAliasCount: () -> () = {}
    public var invokedGetAliasCountfunction = false
    public var invokedGetAliasCountCount = 0
    public var invokedGetAliasCountParameters: (userId: String, Void)?
    public var invokedGetAliasCountParametersList = [(userId: String, Void)]()
    public var stubbedGetAliasCountResult: Int!

    public func getAliasCount(userId: String) async throws -> Int {
        invokedGetAliasCountfunction = true
        invokedGetAliasCountCount += 1
        invokedGetAliasCountParameters = (userId, ())
        invokedGetAliasCountParametersList.append((userId, ()))
        if let error = getAliasCountUserIdThrowableError8 {
            throw error
        }
        closureGetAliasCount()
        return stubbedGetAliasCountResult
    }
    // MARK: - upsertItemsItems
    public var upsertItemsThrowableError9: Error?
    public var closureUpsertItemsItemsAsync9: () -> () = {}
    public var invokedUpsertItemsItemsAsync9 = false
    public var invokedUpsertItemsItemsAsyncCount9 = 0
    public var invokedUpsertItemsItemsAsyncParameters9: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUpsertItemsItemsAsyncParametersList9 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUpsertItemsItemsAsync9 = true
        invokedUpsertItemsItemsAsyncCount9 += 1
        invokedUpsertItemsItemsAsyncParameters9 = (items, ())
        invokedUpsertItemsItemsAsyncParametersList9.append((items, ()))
        if let error = upsertItemsThrowableError9 {
            throw error
        }
        closureUpsertItemsItemsAsync9()
    }
    // MARK: - upsertItemsItemsModifiedItems
    public var upsertItemsModifiedItemsThrowableError10: Error?
    public var closureUpsertItemsItemsModifiedItemsAsync10: () -> () = {}
    public var invokedUpsertItemsItemsModifiedItemsAsync10 = false
    public var invokedUpsertItemsItemsModifiedItemsAsyncCount10 = 0
    public var invokedUpsertItemsItemsModifiedItemsAsyncParameters10: (items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])?
    public var invokedUpsertItemsItemsModifiedItemsAsyncParametersList10 = [(items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem]) async throws {
        invokedUpsertItemsItemsModifiedItemsAsync10 = true
        invokedUpsertItemsItemsModifiedItemsAsyncCount10 += 1
        invokedUpsertItemsItemsModifiedItemsAsyncParameters10 = (items, modifiedItems)
        invokedUpsertItemsItemsModifiedItemsAsyncParametersList10.append((items, modifiedItems))
        if let error = upsertItemsModifiedItemsThrowableError10 {
            throw error
        }
        closureUpsertItemsItemsModifiedItemsAsync10()
    }
    // MARK: - update
    public var updateLastUseItemsShareIdThrowableError11: Error?
    public var closureUpdate: () -> () = {}
    public var invokedUpdatefunction = false
    public var invokedUpdateCount = 0
    public var invokedUpdateParameters: (lastUseItems: [LastUseItem], shareId: String)?
    public var invokedUpdateParametersList = [(lastUseItems: [LastUseItem], shareId: String)]()

    public func update(lastUseItems: [LastUseItem], shareId: String) async throws {
        invokedUpdatefunction = true
        invokedUpdateCount += 1
        invokedUpdateParameters = (lastUseItems, shareId)
        invokedUpdateParametersList.append((lastUseItems, shareId))
        if let error = updateLastUseItemsShareIdThrowableError11 {
            throw error
        }
        closureUpdate()
    }
    // MARK: - deleteItemsItems
    public var deleteItemsThrowableError12: Error?
    public var closureDeleteItemsItemsAsync12: () -> () = {}
    public var invokedDeleteItemsItemsAsync12 = false
    public var invokedDeleteItemsItemsAsyncCount12 = 0
    public var invokedDeleteItemsItemsAsyncParameters12: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedDeleteItemsItemsAsyncParametersList12 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func deleteItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedDeleteItemsItemsAsync12 = true
        invokedDeleteItemsItemsAsyncCount12 += 1
        invokedDeleteItemsItemsAsyncParameters12 = (items, ())
        invokedDeleteItemsItemsAsyncParametersList12.append((items, ()))
        if let error = deleteItemsThrowableError12 {
            throw error
        }
        closureDeleteItemsItemsAsync12()
    }
    // MARK: - deleteItemsItemIdsShareId
    public var deleteItemsItemIdsShareIdThrowableError13: Error?
    public var closureDeleteItemsItemIdsShareIdAsync13: () -> () = {}
    public var invokedDeleteItemsItemIdsShareIdAsync13 = false
    public var invokedDeleteItemsItemIdsShareIdAsyncCount13 = 0
    public var invokedDeleteItemsItemIdsShareIdAsyncParameters13: (itemIds: [String], shareId: String)?
    public var invokedDeleteItemsItemIdsShareIdAsyncParametersList13 = [(itemIds: [String], shareId: String)]()

    public func deleteItems(itemIds: [String], shareId: String) async throws {
        invokedDeleteItemsItemIdsShareIdAsync13 = true
        invokedDeleteItemsItemIdsShareIdAsyncCount13 += 1
        invokedDeleteItemsItemIdsShareIdAsyncParameters13 = (itemIds, shareId)
        invokedDeleteItemsItemIdsShareIdAsyncParametersList13.append((itemIds, shareId))
        if let error = deleteItemsItemIdsShareIdThrowableError13 {
            throw error
        }
        closureDeleteItemsItemIdsShareIdAsync13()
    }
    // MARK: - removeAllItems
    public var removeAllItemsThrowableError14: Error?
    public var closureRemoveAllItemsAsync14: () -> () = {}
    public var invokedRemoveAllItemsAsync14 = false
    public var invokedRemoveAllItemsAsyncCount14 = 0

    public func removeAllItems() async throws {
        invokedRemoveAllItemsAsync14 = true
        invokedRemoveAllItemsAsyncCount14 += 1
        if let error = removeAllItemsThrowableError14 {
            throw error
        }
        closureRemoveAllItemsAsync14()
    }
    // MARK: - removeAllItemsShareId
    public var removeAllItemsShareIdThrowableError15: Error?
    public var closureRemoveAllItemsShareIdAsync15: () -> () = {}
    public var invokedRemoveAllItemsShareIdAsync15 = false
    public var invokedRemoveAllItemsShareIdAsyncCount15 = 0
    public var invokedRemoveAllItemsShareIdAsyncParameters15: (shareId: String, Void)?
    public var invokedRemoveAllItemsShareIdAsyncParametersList15 = [(shareId: String, Void)]()

    public func removeAllItems(shareId: String) async throws {
        invokedRemoveAllItemsShareIdAsync15 = true
        invokedRemoveAllItemsShareIdAsyncCount15 += 1
        invokedRemoveAllItemsShareIdAsyncParameters15 = (shareId, ())
        invokedRemoveAllItemsShareIdAsyncParametersList15.append((shareId, ()))
        if let error = removeAllItemsShareIdThrowableError15 {
            throw error
        }
        closureRemoveAllItemsShareIdAsync15()
    }
    // MARK: - removeAllItemsUserId
    public var removeAllItemsUserIdThrowableError16: Error?
    public var closureRemoveAllItemsUserIdAsync16: () -> () = {}
    public var invokedRemoveAllItemsUserIdAsync16 = false
    public var invokedRemoveAllItemsUserIdAsyncCount16 = 0
    public var invokedRemoveAllItemsUserIdAsyncParameters16: (userId: String, Void)?
    public var invokedRemoveAllItemsUserIdAsyncParametersList16 = [(userId: String, Void)]()

    public func removeAllItems(userId: String) async throws {
        invokedRemoveAllItemsUserIdAsync16 = true
        invokedRemoveAllItemsUserIdAsyncCount16 += 1
        invokedRemoveAllItemsUserIdAsyncParameters16 = (userId, ())
        invokedRemoveAllItemsUserIdAsyncParametersList16.append((userId, ()))
        if let error = removeAllItemsUserIdThrowableError16 {
            throw error
        }
        closureRemoveAllItemsUserIdAsync16()
    }
    // MARK: - getActiveLogInItems
    public var getActiveLogInItemsUserIdThrowableError17: Error?
    public var closureGetActiveLogInItems: () -> () = {}
    public var invokedGetActiveLogInItemsfunction = false
    public var invokedGetActiveLogInItemsCount = 0
    public var invokedGetActiveLogInItemsParameters: (userId: String, Void)?
    public var invokedGetActiveLogInItemsParametersList = [(userId: String, Void)]()
    public var stubbedGetActiveLogInItemsResult: [SymmetricallyEncryptedItem]!

    public func getActiveLogInItems(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetActiveLogInItemsfunction = true
        invokedGetActiveLogInItemsCount += 1
        invokedGetActiveLogInItemsParameters = (userId, ())
        invokedGetActiveLogInItemsParametersList.append((userId, ()))
        if let error = getActiveLogInItemsUserIdThrowableError17 {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
    // MARK: - getItemsItems
    public var getItemsForThrowableError18: Error?
    public var closureGetItemsItemsAsync18: () -> () = {}
    public var invokedGetItemsItemsAsync18 = false
    public var invokedGetItemsItemsAsyncCount18 = 0
    public var invokedGetItemsItemsAsyncParameters18: (items: [any ItemIdentifiable], Void)?
    public var invokedGetItemsItemsAsyncParametersList18 = [(items: [any ItemIdentifiable], Void)]()
    public var stubbedGetItemsItemsAsyncResult18: [SymmetricallyEncryptedItem]!

    public func getItems(for items: [any ItemIdentifiable]) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsItemsAsync18 = true
        invokedGetItemsItemsAsyncCount18 += 1
        invokedGetItemsItemsAsyncParameters18 = (items, ())
        invokedGetItemsItemsAsyncParametersList18.append((items, ()))
        if let error = getItemsForThrowableError18 {
            throw error
        }
        closureGetItemsItemsAsync18()
        return stubbedGetItemsItemsAsyncResult18
    }
}
