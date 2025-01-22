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
    // MARK: - upsertItemsItems
    public var upsertItemsThrowableError8: Error?
    public var closureUpsertItemsItemsAsync8: () -> () = {}
    public var invokedUpsertItemsItemsAsync8 = false
    public var invokedUpsertItemsItemsAsyncCount8 = 0
    public var invokedUpsertItemsItemsAsyncParameters8: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUpsertItemsItemsAsyncParametersList8 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUpsertItemsItemsAsync8 = true
        invokedUpsertItemsItemsAsyncCount8 += 1
        invokedUpsertItemsItemsAsyncParameters8 = (items, ())
        invokedUpsertItemsItemsAsyncParametersList8.append((items, ()))
        if let error = upsertItemsThrowableError8 {
            throw error
        }
        closureUpsertItemsItemsAsync8()
    }
    // MARK: - upsertItemsItemsModifiedItems
    public var upsertItemsModifiedItemsThrowableError9: Error?
    public var closureUpsertItemsItemsModifiedItemsAsync9: () -> () = {}
    public var invokedUpsertItemsItemsModifiedItemsAsync9 = false
    public var invokedUpsertItemsItemsModifiedItemsAsyncCount9 = 0
    public var invokedUpsertItemsItemsModifiedItemsAsyncParameters9: (items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])?
    public var invokedUpsertItemsItemsModifiedItemsAsyncParametersList9 = [(items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem]) async throws {
        invokedUpsertItemsItemsModifiedItemsAsync9 = true
        invokedUpsertItemsItemsModifiedItemsAsyncCount9 += 1
        invokedUpsertItemsItemsModifiedItemsAsyncParameters9 = (items, modifiedItems)
        invokedUpsertItemsItemsModifiedItemsAsyncParametersList9.append((items, modifiedItems))
        if let error = upsertItemsModifiedItemsThrowableError9 {
            throw error
        }
        closureUpsertItemsItemsModifiedItemsAsync9()
    }
    // MARK: - update
    public var updateLastUseItemsShareIdThrowableError10: Error?
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
        if let error = updateLastUseItemsShareIdThrowableError10 {
            throw error
        }
        closureUpdate()
    }
    // MARK: - deleteItemsItems
    public var deleteItemsThrowableError11: Error?
    public var closureDeleteItemsItemsAsync11: () -> () = {}
    public var invokedDeleteItemsItemsAsync11 = false
    public var invokedDeleteItemsItemsAsyncCount11 = 0
    public var invokedDeleteItemsItemsAsyncParameters11: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedDeleteItemsItemsAsyncParametersList11 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func deleteItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedDeleteItemsItemsAsync11 = true
        invokedDeleteItemsItemsAsyncCount11 += 1
        invokedDeleteItemsItemsAsyncParameters11 = (items, ())
        invokedDeleteItemsItemsAsyncParametersList11.append((items, ()))
        if let error = deleteItemsThrowableError11 {
            throw error
        }
        closureDeleteItemsItemsAsync11()
    }
    // MARK: - deleteItemsItemIdsShareId
    public var deleteItemsItemIdsShareIdThrowableError12: Error?
    public var closureDeleteItemsItemIdsShareIdAsync12: () -> () = {}
    public var invokedDeleteItemsItemIdsShareIdAsync12 = false
    public var invokedDeleteItemsItemIdsShareIdAsyncCount12 = 0
    public var invokedDeleteItemsItemIdsShareIdAsyncParameters12: (itemIds: [String], shareId: String)?
    public var invokedDeleteItemsItemIdsShareIdAsyncParametersList12 = [(itemIds: [String], shareId: String)]()

    public func deleteItems(itemIds: [String], shareId: String) async throws {
        invokedDeleteItemsItemIdsShareIdAsync12 = true
        invokedDeleteItemsItemIdsShareIdAsyncCount12 += 1
        invokedDeleteItemsItemIdsShareIdAsyncParameters12 = (itemIds, shareId)
        invokedDeleteItemsItemIdsShareIdAsyncParametersList12.append((itemIds, shareId))
        if let error = deleteItemsItemIdsShareIdThrowableError12 {
            throw error
        }
        closureDeleteItemsItemIdsShareIdAsync12()
    }
    // MARK: - removeAllItems
    public var removeAllItemsThrowableError13: Error?
    public var closureRemoveAllItemsAsync13: () -> () = {}
    public var invokedRemoveAllItemsAsync13 = false
    public var invokedRemoveAllItemsAsyncCount13 = 0

    public func removeAllItems() async throws {
        invokedRemoveAllItemsAsync13 = true
        invokedRemoveAllItemsAsyncCount13 += 1
        if let error = removeAllItemsThrowableError13 {
            throw error
        }
        closureRemoveAllItemsAsync13()
    }
    // MARK: - removeAllItemsShareId
    public var removeAllItemsShareIdThrowableError14: Error?
    public var closureRemoveAllItemsShareIdAsync14: () -> () = {}
    public var invokedRemoveAllItemsShareIdAsync14 = false
    public var invokedRemoveAllItemsShareIdAsyncCount14 = 0
    public var invokedRemoveAllItemsShareIdAsyncParameters14: (shareId: String, Void)?
    public var invokedRemoveAllItemsShareIdAsyncParametersList14 = [(shareId: String, Void)]()

    public func removeAllItems(shareId: String) async throws {
        invokedRemoveAllItemsShareIdAsync14 = true
        invokedRemoveAllItemsShareIdAsyncCount14 += 1
        invokedRemoveAllItemsShareIdAsyncParameters14 = (shareId, ())
        invokedRemoveAllItemsShareIdAsyncParametersList14.append((shareId, ()))
        if let error = removeAllItemsShareIdThrowableError14 {
            throw error
        }
        closureRemoveAllItemsShareIdAsync14()
    }
    // MARK: - removeAllItemsUserId
    public var removeAllItemsUserIdThrowableError15: Error?
    public var closureRemoveAllItemsUserIdAsync15: () -> () = {}
    public var invokedRemoveAllItemsUserIdAsync15 = false
    public var invokedRemoveAllItemsUserIdAsyncCount15 = 0
    public var invokedRemoveAllItemsUserIdAsyncParameters15: (userId: String, Void)?
    public var invokedRemoveAllItemsUserIdAsyncParametersList15 = [(userId: String, Void)]()

    public func removeAllItems(userId: String) async throws {
        invokedRemoveAllItemsUserIdAsync15 = true
        invokedRemoveAllItemsUserIdAsyncCount15 += 1
        invokedRemoveAllItemsUserIdAsyncParameters15 = (userId, ())
        invokedRemoveAllItemsUserIdAsyncParametersList15.append((userId, ()))
        if let error = removeAllItemsUserIdThrowableError15 {
            throw error
        }
        closureRemoveAllItemsUserIdAsync15()
    }
    // MARK: - getActiveLogInItems
    public var getActiveLogInItemsUserIdThrowableError16: Error?
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
        if let error = getActiveLogInItemsUserIdThrowableError16 {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
    // MARK: - getItemsItems
    public var getItemsForThrowableError17: Error?
    public var closureGetItemsItemsAsync17: () -> () = {}
    public var invokedGetItemsItemsAsync17 = false
    public var invokedGetItemsItemsAsyncCount17 = 0
    public var invokedGetItemsItemsAsyncParameters17: (items: [any ItemIdentifiable], Void)?
    public var invokedGetItemsItemsAsyncParametersList17 = [(items: [any ItemIdentifiable], Void)]()
    public var stubbedGetItemsItemsAsyncResult17: [SymmetricallyEncryptedItem]!

    public func getItems(for items: [any ItemIdentifiable]) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsItemsAsync17 = true
        invokedGetItemsItemsAsyncCount17 += 1
        invokedGetItemsItemsAsyncParameters17 = (items, ())
        invokedGetItemsItemsAsyncParametersList17.append((items, ()))
        if let error = getItemsForThrowableError17 {
            throw error
        }
        closureGetItemsItemsAsync17()
        return stubbedGetItemsItemsAsyncResult17
    }
}
