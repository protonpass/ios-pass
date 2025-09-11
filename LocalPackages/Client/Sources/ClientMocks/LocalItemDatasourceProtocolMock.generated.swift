// Generated using Sourcery 2.2.7 — https://github.com/krzysztofzablocki/Sourcery
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
    // MARK: - getUnsyncedSimpleLoginNoteAliases
    public var getUnsyncedSimpleLoginNoteAliasesUserIdPageSizeThrowableError9: Error?
    public var closureGetUnsyncedSimpleLoginNoteAliases: () -> () = {}
    public var invokedGetUnsyncedSimpleLoginNoteAliasesfunction = false
    public var invokedGetUnsyncedSimpleLoginNoteAliasesCount = 0
    public var invokedGetUnsyncedSimpleLoginNoteAliasesParameters: (userId: String, pageSize: Int)?
    public var invokedGetUnsyncedSimpleLoginNoteAliasesParametersList = [(userId: String, pageSize: Int)]()
    public var stubbedGetUnsyncedSimpleLoginNoteAliasesResult: [SymmetricallyEncryptedItem]!

    public func getUnsyncedSimpleLoginNoteAliases(userId: String, pageSize: Int) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetUnsyncedSimpleLoginNoteAliasesfunction = true
        invokedGetUnsyncedSimpleLoginNoteAliasesCount += 1
        invokedGetUnsyncedSimpleLoginNoteAliasesParameters = (userId, pageSize)
        invokedGetUnsyncedSimpleLoginNoteAliasesParametersList.append((userId, pageSize))
        if let error = getUnsyncedSimpleLoginNoteAliasesUserIdPageSizeThrowableError9 {
            throw error
        }
        closureGetUnsyncedSimpleLoginNoteAliases()
        return stubbedGetUnsyncedSimpleLoginNoteAliasesResult
    }
    // MARK: - updateCachedAliasInfo
    public var updateCachedAliasInfoItemsAliasesThrowableError10: Error?
    public var closureUpdateCachedAliasInfo: () -> () = {}
    public var invokedUpdateCachedAliasInfofunction = false
    public var invokedUpdateCachedAliasInfoCount = 0
    public var invokedUpdateCachedAliasInfoParameters: (items: [SymmetricallyEncryptedItem], aliases: [SymmetricallyEncryptedAlias])?
    public var invokedUpdateCachedAliasInfoParametersList = [(items: [SymmetricallyEncryptedItem], aliases: [SymmetricallyEncryptedAlias])]()

    public func updateCachedAliasInfo(items: [SymmetricallyEncryptedItem], aliases: [SymmetricallyEncryptedAlias]) async throws {
        invokedUpdateCachedAliasInfofunction = true
        invokedUpdateCachedAliasInfoCount += 1
        invokedUpdateCachedAliasInfoParameters = (items, aliases)
        invokedUpdateCachedAliasInfoParametersList.append((items, aliases))
        if let error = updateCachedAliasInfoItemsAliasesThrowableError10 {
            throw error
        }
        closureUpdateCachedAliasInfo()
    }
    // MARK: - upsertItemsItems
    public var upsertItemsThrowableError11: Error?
    public var closureUpsertItemsItemsAsync11: () -> () = {}
    public var invokedUpsertItemsItemsAsync11 = false
    public var invokedUpsertItemsItemsAsyncCount11 = 0
    public var invokedUpsertItemsItemsAsyncParameters11: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUpsertItemsItemsAsyncParametersList11 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUpsertItemsItemsAsync11 = true
        invokedUpsertItemsItemsAsyncCount11 += 1
        invokedUpsertItemsItemsAsyncParameters11 = (items, ())
        invokedUpsertItemsItemsAsyncParametersList11.append((items, ()))
        if let error = upsertItemsThrowableError11 {
            throw error
        }
        closureUpsertItemsItemsAsync11()
    }
    // MARK: - upsertItemsItemsModifiedItems
    public var upsertItemsModifiedItemsThrowableError12: Error?
    public var closureUpsertItemsItemsModifiedItemsAsync12: () -> () = {}
    public var invokedUpsertItemsItemsModifiedItemsAsync12 = false
    public var invokedUpsertItemsItemsModifiedItemsAsyncCount12 = 0
    public var invokedUpsertItemsItemsModifiedItemsAsyncParameters12: (items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])?
    public var invokedUpsertItemsItemsModifiedItemsAsyncParametersList12 = [(items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem]) async throws {
        invokedUpsertItemsItemsModifiedItemsAsync12 = true
        invokedUpsertItemsItemsModifiedItemsAsyncCount12 += 1
        invokedUpsertItemsItemsModifiedItemsAsyncParameters12 = (items, modifiedItems)
        invokedUpsertItemsItemsModifiedItemsAsyncParametersList12.append((items, modifiedItems))
        if let error = upsertItemsModifiedItemsThrowableError12 {
            throw error
        }
        closureUpsertItemsItemsModifiedItemsAsync12()
    }
    // MARK: - update
    public var updateLastUseItemsShareIdThrowableError13: Error?
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
        if let error = updateLastUseItemsShareIdThrowableError13 {
            throw error
        }
        closureUpdate()
    }
    // MARK: - deleteItemsItems
    public var deleteItemsThrowableError14: Error?
    public var closureDeleteItemsItemsAsync14: () -> () = {}
    public var invokedDeleteItemsItemsAsync14 = false
    public var invokedDeleteItemsItemsAsyncCount14 = 0
    public var invokedDeleteItemsItemsAsyncParameters14: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedDeleteItemsItemsAsyncParametersList14 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func deleteItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedDeleteItemsItemsAsync14 = true
        invokedDeleteItemsItemsAsyncCount14 += 1
        invokedDeleteItemsItemsAsyncParameters14 = (items, ())
        invokedDeleteItemsItemsAsyncParametersList14.append((items, ()))
        if let error = deleteItemsThrowableError14 {
            throw error
        }
        closureDeleteItemsItemsAsync14()
    }
    // MARK: - deleteItemsItemIdsShareId
    public var deleteItemsItemIdsShareIdThrowableError15: Error?
    public var closureDeleteItemsItemIdsShareIdAsync15: () -> () = {}
    public var invokedDeleteItemsItemIdsShareIdAsync15 = false
    public var invokedDeleteItemsItemIdsShareIdAsyncCount15 = 0
    public var invokedDeleteItemsItemIdsShareIdAsyncParameters15: (itemIds: [String], shareId: String)?
    public var invokedDeleteItemsItemIdsShareIdAsyncParametersList15 = [(itemIds: [String], shareId: String)]()

    public func deleteItems(itemIds: [String], shareId: String) async throws {
        invokedDeleteItemsItemIdsShareIdAsync15 = true
        invokedDeleteItemsItemIdsShareIdAsyncCount15 += 1
        invokedDeleteItemsItemIdsShareIdAsyncParameters15 = (itemIds, shareId)
        invokedDeleteItemsItemIdsShareIdAsyncParametersList15.append((itemIds, shareId))
        if let error = deleteItemsItemIdsShareIdThrowableError15 {
            throw error
        }
        closureDeleteItemsItemIdsShareIdAsync15()
    }
    // MARK: - removeAllItems
    public var removeAllItemsThrowableError16: Error?
    public var closureRemoveAllItemsAsync16: () -> () = {}
    public var invokedRemoveAllItemsAsync16 = false
    public var invokedRemoveAllItemsAsyncCount16 = 0

    public func removeAllItems() async throws {
        invokedRemoveAllItemsAsync16 = true
        invokedRemoveAllItemsAsyncCount16 += 1
        if let error = removeAllItemsThrowableError16 {
            throw error
        }
        closureRemoveAllItemsAsync16()
    }
    // MARK: - removeAllItemsShareId
    public var removeAllItemsShareIdThrowableError17: Error?
    public var closureRemoveAllItemsShareIdAsync17: () -> () = {}
    public var invokedRemoveAllItemsShareIdAsync17 = false
    public var invokedRemoveAllItemsShareIdAsyncCount17 = 0
    public var invokedRemoveAllItemsShareIdAsyncParameters17: (shareId: String, Void)?
    public var invokedRemoveAllItemsShareIdAsyncParametersList17 = [(shareId: String, Void)]()

    public func removeAllItems(shareId: String) async throws {
        invokedRemoveAllItemsShareIdAsync17 = true
        invokedRemoveAllItemsShareIdAsyncCount17 += 1
        invokedRemoveAllItemsShareIdAsyncParameters17 = (shareId, ())
        invokedRemoveAllItemsShareIdAsyncParametersList17.append((shareId, ()))
        if let error = removeAllItemsShareIdThrowableError17 {
            throw error
        }
        closureRemoveAllItemsShareIdAsync17()
    }
    // MARK: - removeAllItemsUserId
    public var removeAllItemsUserIdThrowableError18: Error?
    public var closureRemoveAllItemsUserIdAsync18: () -> () = {}
    public var invokedRemoveAllItemsUserIdAsync18 = false
    public var invokedRemoveAllItemsUserIdAsyncCount18 = 0
    public var invokedRemoveAllItemsUserIdAsyncParameters18: (userId: String, Void)?
    public var invokedRemoveAllItemsUserIdAsyncParametersList18 = [(userId: String, Void)]()

    public func removeAllItems(userId: String) async throws {
        invokedRemoveAllItemsUserIdAsync18 = true
        invokedRemoveAllItemsUserIdAsyncCount18 += 1
        invokedRemoveAllItemsUserIdAsyncParameters18 = (userId, ())
        invokedRemoveAllItemsUserIdAsyncParametersList18.append((userId, ()))
        if let error = removeAllItemsUserIdThrowableError18 {
            throw error
        }
        closureRemoveAllItemsUserIdAsync18()
    }
    // MARK: - getActiveLogInItems
    public var getActiveLogInItemsUserIdThrowableError19: Error?
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
        if let error = getActiveLogInItemsUserIdThrowableError19 {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
    // MARK: - getItemsItems
    public var getItemsForThrowableError20: Error?
    public var closureGetItemsItemsAsync20: () -> () = {}
    public var invokedGetItemsItemsAsync20 = false
    public var invokedGetItemsItemsAsyncCount20 = 0
    public var invokedGetItemsItemsAsyncParameters20: (items: [any ItemIdentifiable], Void)?
    public var invokedGetItemsItemsAsyncParametersList20 = [(items: [any ItemIdentifiable], Void)]()
    public var stubbedGetItemsItemsAsyncResult20: [SymmetricallyEncryptedItem]!

    public func getItems(for items: [any ItemIdentifiable]) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsItemsAsync20 = true
        invokedGetItemsItemsAsyncCount20 += 1
        invokedGetItemsItemsAsyncParameters20 = (items, ())
        invokedGetItemsItemsAsyncParametersList20.append((items, ()))
        if let error = getItemsForThrowableError20 {
            throw error
        }
        closureGetItemsItemsAsync20()
        return stubbedGetItemsItemsAsyncResult20
    }
}
