// Generated using Sourcery 2.0.2 — https://github.com/krzysztofzablocki/Sourcery
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
    public var getAllItemsThrowableError1: Error?
    public var closureGetAllItems: () -> () = {}
    public var invokedGetAllItemsfunction = false
    public var invokedGetAllItemsCount = 0
    public var stubbedGetAllItemsResult: [SymmetricallyEncryptedItem]!

    public func getAllItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetAllItemsfunction = true
        invokedGetAllItemsCount += 1
        if let error = getAllItemsThrowableError1 {
            throw error
        }
        closureGetAllItems()
        return stubbedGetAllItemsResult
    }
    // MARK: - getItemsState
    public var getItemsStateThrowableError2: Error?
    public var closureGetItemsStateAsync2: () -> () = {}
    public var invokedGetItemsStateAsync2 = false
    public var invokedGetItemsStateAsyncCount2 = 0
    public var invokedGetItemsStateAsyncParameters2: (state: ItemState, Void)?
    public var invokedGetItemsStateAsyncParametersList2 = [(state: ItemState, Void)]()
    public var stubbedGetItemsStateAsyncResult2: [SymmetricallyEncryptedItem]!

    public func getItems(state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsStateAsync2 = true
        invokedGetItemsStateAsyncCount2 += 1
        invokedGetItemsStateAsyncParameters2 = (state, ())
        invokedGetItemsStateAsyncParametersList2.append((state, ()))
        if let error = getItemsStateThrowableError2 {
            throw error
        }
        closureGetItemsStateAsync2()
        return stubbedGetItemsStateAsyncResult2
    }
    // MARK: - getItemsShareIdState
    public var getItemsShareIdStateThrowableError3: Error?
    public var closureGetItemsShareIdStateAsync3: () -> () = {}
    public var invokedGetItemsShareIdStateAsync3 = false
    public var invokedGetItemsShareIdStateAsyncCount3 = 0
    public var invokedGetItemsShareIdStateAsyncParameters3: (shareId: String, state: ItemState)?
    public var invokedGetItemsShareIdStateAsyncParametersList3 = [(shareId: String, state: ItemState)]()
    public var stubbedGetItemsShareIdStateAsyncResult3: [SymmetricallyEncryptedItem]!

    public func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsShareIdStateAsync3 = true
        invokedGetItemsShareIdStateAsyncCount3 += 1
        invokedGetItemsShareIdStateAsyncParameters3 = (shareId, state)
        invokedGetItemsShareIdStateAsyncParametersList3.append((shareId, state))
        if let error = getItemsShareIdStateThrowableError3 {
            throw error
        }
        closureGetItemsShareIdStateAsync3()
        return stubbedGetItemsShareIdStateAsyncResult3
    }
    // MARK: - getItem
    public var getItemShareIdItemIdThrowableError4: Error?
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
        if let error = getItemShareIdItemIdThrowableError4 {
            throw error
        }
        closureGetItem()
        return stubbedGetItemResult
    }
    // MARK: - getAliasItem
    public var getAliasItemEmailThrowableError5: Error?
    public var closureGetAliasItem: () -> () = {}
    public var invokedGetAliasItemfunction = false
    public var invokedGetAliasItemCount = 0
    public var invokedGetAliasItemParameters: (email: String, Void)?
    public var invokedGetAliasItemParametersList = [(email: String, Void)]()
    public var stubbedGetAliasItemResult: SymmetricallyEncryptedItem?

    public func getAliasItem(email: String) async throws -> SymmetricallyEncryptedItem? {
        invokedGetAliasItemfunction = true
        invokedGetAliasItemCount += 1
        invokedGetAliasItemParameters = (email, ())
        invokedGetAliasItemParametersList.append((email, ()))
        if let error = getAliasItemEmailThrowableError5 {
            throw error
        }
        closureGetAliasItem()
        return stubbedGetAliasItemResult
    }
    // MARK: - getItemCount
    public var getItemCountShareIdThrowableError6: Error?
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
        if let error = getItemCountShareIdThrowableError6 {
            throw error
        }
        closureGetItemCount()
        return stubbedGetItemCountResult
    }
    // MARK: - upsertItemsItems
    public var upsertItemsThrowableError7: Error?
    public var closureUpsertItemsItemsAsync7: () -> () = {}
    public var invokedUpsertItemsItemsAsync7 = false
    public var invokedUpsertItemsItemsAsyncCount7 = 0
    public var invokedUpsertItemsItemsAsyncParameters7: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUpsertItemsItemsAsyncParametersList7 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUpsertItemsItemsAsync7 = true
        invokedUpsertItemsItemsAsyncCount7 += 1
        invokedUpsertItemsItemsAsyncParameters7 = (items, ())
        invokedUpsertItemsItemsAsyncParametersList7.append((items, ()))
        if let error = upsertItemsThrowableError7 {
            throw error
        }
        closureUpsertItemsItemsAsync7()
    }
    // MARK: - upsertItemsItemsModifiedItems
    public var upsertItemsModifiedItemsThrowableError8: Error?
    public var closureUpsertItemsItemsModifiedItemsAsync8: () -> () = {}
    public var invokedUpsertItemsItemsModifiedItemsAsync8 = false
    public var invokedUpsertItemsItemsModifiedItemsAsyncCount8 = 0
    public var invokedUpsertItemsItemsModifiedItemsAsyncParameters8: (items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])?
    public var invokedUpsertItemsItemsModifiedItemsAsyncParametersList8 = [(items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem]) async throws {
        invokedUpsertItemsItemsModifiedItemsAsync8 = true
        invokedUpsertItemsItemsModifiedItemsAsyncCount8 += 1
        invokedUpsertItemsItemsModifiedItemsAsyncParameters8 = (items, modifiedItems)
        invokedUpsertItemsItemsModifiedItemsAsyncParametersList8.append((items, modifiedItems))
        if let error = upsertItemsModifiedItemsThrowableError8 {
            throw error
        }
        closureUpsertItemsItemsModifiedItemsAsync8()
    }
    // MARK: - update
    public var updateLastUseItemsShareIdThrowableError9: Error?
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
        if let error = updateLastUseItemsShareIdThrowableError9 {
            throw error
        }
        closureUpdate()
    }
    // MARK: - deleteItemsItems
    public var deleteItemsThrowableError10: Error?
    public var closureDeleteItemsItemsAsync10: () -> () = {}
    public var invokedDeleteItemsItemsAsync10 = false
    public var invokedDeleteItemsItemsAsyncCount10 = 0
    public var invokedDeleteItemsItemsAsyncParameters10: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedDeleteItemsItemsAsyncParametersList10 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func deleteItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedDeleteItemsItemsAsync10 = true
        invokedDeleteItemsItemsAsyncCount10 += 1
        invokedDeleteItemsItemsAsyncParameters10 = (items, ())
        invokedDeleteItemsItemsAsyncParametersList10.append((items, ()))
        if let error = deleteItemsThrowableError10 {
            throw error
        }
        closureDeleteItemsItemsAsync10()
    }
    // MARK: - deleteItemsItemIdsShareId
    public var deleteItemsItemIdsShareIdThrowableError11: Error?
    public var closureDeleteItemsItemIdsShareIdAsync11: () -> () = {}
    public var invokedDeleteItemsItemIdsShareIdAsync11 = false
    public var invokedDeleteItemsItemIdsShareIdAsyncCount11 = 0
    public var invokedDeleteItemsItemIdsShareIdAsyncParameters11: (itemIds: [String], shareId: String)?
    public var invokedDeleteItemsItemIdsShareIdAsyncParametersList11 = [(itemIds: [String], shareId: String)]()

    public func deleteItems(itemIds: [String], shareId: String) async throws {
        invokedDeleteItemsItemIdsShareIdAsync11 = true
        invokedDeleteItemsItemIdsShareIdAsyncCount11 += 1
        invokedDeleteItemsItemIdsShareIdAsyncParameters11 = (itemIds, shareId)
        invokedDeleteItemsItemIdsShareIdAsyncParametersList11.append((itemIds, shareId))
        if let error = deleteItemsItemIdsShareIdThrowableError11 {
            throw error
        }
        closureDeleteItemsItemIdsShareIdAsync11()
    }
    // MARK: - removeAllItems
    public var removeAllItemsThrowableError12: Error?
    public var closureRemoveAllItemsAsync12: () -> () = {}
    public var invokedRemoveAllItemsAsync12 = false
    public var invokedRemoveAllItemsAsyncCount12 = 0

    public func removeAllItems() async throws {
        invokedRemoveAllItemsAsync12 = true
        invokedRemoveAllItemsAsyncCount12 += 1
        if let error = removeAllItemsThrowableError12 {
            throw error
        }
        closureRemoveAllItemsAsync12()
    }
    // MARK: - removeAllItemsShareId
    public var removeAllItemsShareIdThrowableError13: Error?
    public var closureRemoveAllItemsShareIdAsync13: () -> () = {}
    public var invokedRemoveAllItemsShareIdAsync13 = false
    public var invokedRemoveAllItemsShareIdAsyncCount13 = 0
    public var invokedRemoveAllItemsShareIdAsyncParameters13: (shareId: String, Void)?
    public var invokedRemoveAllItemsShareIdAsyncParametersList13 = [(shareId: String, Void)]()

    public func removeAllItems(shareId: String) async throws {
        invokedRemoveAllItemsShareIdAsync13 = true
        invokedRemoveAllItemsShareIdAsyncCount13 += 1
        invokedRemoveAllItemsShareIdAsyncParameters13 = (shareId, ())
        invokedRemoveAllItemsShareIdAsyncParametersList13.append((shareId, ()))
        if let error = removeAllItemsShareIdThrowableError13 {
            throw error
        }
        closureRemoveAllItemsShareIdAsync13()
    }
    // MARK: - getActiveLogInItems
    public var getActiveLogInItemsThrowableError14: Error?
    public var closureGetActiveLogInItems: () -> () = {}
    public var invokedGetActiveLogInItemsfunction = false
    public var invokedGetActiveLogInItemsCount = 0
    public var stubbedGetActiveLogInItemsResult: [SymmetricallyEncryptedItem]!

    public func getActiveLogInItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetActiveLogInItemsfunction = true
        invokedGetActiveLogInItemsCount += 1
        if let error = getActiveLogInItemsThrowableError14 {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
    // MARK: - getAllPinnedItems
    public var getAllPinnedItemsThrowableError15: Error?
    public var closureGetAllPinnedItems: () -> () = {}
    public var invokedGetAllPinnedItemsfunction = false
    public var invokedGetAllPinnedItemsCount = 0
    public var stubbedGetAllPinnedItemsResult: [SymmetricallyEncryptedItem]!

    public func getAllPinnedItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetAllPinnedItemsfunction = true
        invokedGetAllPinnedItemsCount += 1
        if let error = getAllPinnedItemsThrowableError15 {
            throw error
        }
        closureGetAllPinnedItems()
        return stubbedGetAllPinnedItemsResult
    }
}
