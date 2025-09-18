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
import Core
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
    // MARK: - getItemsIds
    public var getItemsThrowableError5: Error?
    public var closureGetItemsIdsAsync5: () -> () = {}
    public var invokedGetItemsIdsAsync5 = false
    public var invokedGetItemsIdsAsyncCount5 = 0
    public var invokedGetItemsIdsAsyncParameters5: (ids: [any ItemIdentifiable], Void)?
    public var invokedGetItemsIdsAsyncParametersList5 = [(ids: [any ItemIdentifiable], Void)]()
    public var stubbedGetItemsIdsAsyncResult5: [SymmetricallyEncryptedItem]!

    public func getItems(_ ids: [any ItemIdentifiable]) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsIdsAsync5 = true
        invokedGetItemsIdsAsyncCount5 += 1
        invokedGetItemsIdsAsyncParameters5 = (ids, ())
        invokedGetItemsIdsAsyncParametersList5.append((ids, ()))
        if let error = getItemsThrowableError5 {
            throw error
        }
        closureGetItemsIdsAsync5()
        return stubbedGetItemsIdsAsyncResult5
    }
    // MARK: - getItem
    public var getItemShareIdItemIdThrowableError6: Error?
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
        if let error = getItemShareIdItemIdThrowableError6 {
            throw error
        }
        closureGetItem()
        return stubbedGetItemResult
    }
    // MARK: - getAliasItem
    public var getAliasItemEmailShareIdThrowableError7: Error?
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
        if let error = getAliasItemEmailShareIdThrowableError7 {
            throw error
        }
        closureGetAliasItem()
        return stubbedGetAliasItemResult
    }
    // MARK: - getItemCount
    public var getItemCountShareIdThrowableError8: Error?
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
        if let error = getItemCountShareIdThrowableError8 {
            throw error
        }
        closureGetItemCount()
        return stubbedGetItemCountResult
    }
    // MARK: - getAliasCount
    public var getAliasCountUserIdThrowableError9: Error?
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
        if let error = getAliasCountUserIdThrowableError9 {
            throw error
        }
        closureGetAliasCount()
        return stubbedGetAliasCountResult
    }
    // MARK: - getUnsyncedSimpleLoginNoteAliases
    public var getUnsyncedSimpleLoginNoteAliasesUserIdThrowableError10: Error?
    public var closureGetUnsyncedSimpleLoginNoteAliases: () -> () = {}
    public var invokedGetUnsyncedSimpleLoginNoteAliasesfunction = false
    public var invokedGetUnsyncedSimpleLoginNoteAliasesCount = 0
    public var invokedGetUnsyncedSimpleLoginNoteAliasesParameters: (userId: String, Void)?
    public var invokedGetUnsyncedSimpleLoginNoteAliasesParametersList = [(userId: String, Void)]()
    public var stubbedGetUnsyncedSimpleLoginNoteAliasesResult: [SymmetricallyEncryptedItem]!

    public func getUnsyncedSimpleLoginNoteAliases(userId: String) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetUnsyncedSimpleLoginNoteAliasesfunction = true
        invokedGetUnsyncedSimpleLoginNoteAliasesCount += 1
        invokedGetUnsyncedSimpleLoginNoteAliasesParameters = (userId, ())
        invokedGetUnsyncedSimpleLoginNoteAliasesParametersList.append((userId, ()))
        if let error = getUnsyncedSimpleLoginNoteAliasesUserIdThrowableError10 {
            throw error
        }
        closureGetUnsyncedSimpleLoginNoteAliases()
        return stubbedGetUnsyncedSimpleLoginNoteAliasesResult
    }
    // MARK: - updateCachedAliasInfo
    public var updateCachedAliasInfoItemsAliasesThrowableError11: Error?
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
        if let error = updateCachedAliasInfoItemsAliasesThrowableError11 {
            throw error
        }
        closureUpdateCachedAliasInfo()
    }
    // MARK: - upsertItemsItems
    public var upsertItemsThrowableError12: Error?
    public var closureUpsertItemsItemsAsync12: () -> () = {}
    public var invokedUpsertItemsItemsAsync12 = false
    public var invokedUpsertItemsItemsAsyncCount12 = 0
    public var invokedUpsertItemsItemsAsyncParameters12: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUpsertItemsItemsAsyncParametersList12 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUpsertItemsItemsAsync12 = true
        invokedUpsertItemsItemsAsyncCount12 += 1
        invokedUpsertItemsItemsAsyncParameters12 = (items, ())
        invokedUpsertItemsItemsAsyncParametersList12.append((items, ()))
        if let error = upsertItemsThrowableError12 {
            throw error
        }
        closureUpsertItemsItemsAsync12()
    }
    // MARK: - upsertItemsItemsModifiedItems
    public var upsertItemsModifiedItemsThrowableError13: Error?
    public var closureUpsertItemsItemsModifiedItemsAsync13: () -> () = {}
    public var invokedUpsertItemsItemsModifiedItemsAsync13 = false
    public var invokedUpsertItemsItemsModifiedItemsAsyncCount13 = 0
    public var invokedUpsertItemsItemsModifiedItemsAsyncParameters13: (items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])?
    public var invokedUpsertItemsItemsModifiedItemsAsyncParametersList13 = [(items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem]) async throws {
        invokedUpsertItemsItemsModifiedItemsAsync13 = true
        invokedUpsertItemsItemsModifiedItemsAsyncCount13 += 1
        invokedUpsertItemsItemsModifiedItemsAsyncParameters13 = (items, modifiedItems)
        invokedUpsertItemsItemsModifiedItemsAsyncParametersList13.append((items, modifiedItems))
        if let error = upsertItemsModifiedItemsThrowableError13 {
            throw error
        }
        closureUpsertItemsItemsModifiedItemsAsync13()
    }
    // MARK: - update
    public var updateLastUseItemsShareIdThrowableError14: Error?
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
        if let error = updateLastUseItemsShareIdThrowableError14 {
            throw error
        }
        closureUpdate()
    }
    // MARK: - deleteItemsItems
    public var deleteItemsThrowableError15: Error?
    public var closureDeleteItemsItemsAsync15: () -> () = {}
    public var invokedDeleteItemsItemsAsync15 = false
    public var invokedDeleteItemsItemsAsyncCount15 = 0
    public var invokedDeleteItemsItemsAsyncParameters15: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedDeleteItemsItemsAsyncParametersList15 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func deleteItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedDeleteItemsItemsAsync15 = true
        invokedDeleteItemsItemsAsyncCount15 += 1
        invokedDeleteItemsItemsAsyncParameters15 = (items, ())
        invokedDeleteItemsItemsAsyncParametersList15.append((items, ()))
        if let error = deleteItemsThrowableError15 {
            throw error
        }
        closureDeleteItemsItemsAsync15()
    }
    // MARK: - deleteItemsItemIdsShareId
    public var deleteItemsItemIdsShareIdThrowableError16: Error?
    public var closureDeleteItemsItemIdsShareIdAsync16: () -> () = {}
    public var invokedDeleteItemsItemIdsShareIdAsync16 = false
    public var invokedDeleteItemsItemIdsShareIdAsyncCount16 = 0
    public var invokedDeleteItemsItemIdsShareIdAsyncParameters16: (itemIds: [String], shareId: String)?
    public var invokedDeleteItemsItemIdsShareIdAsyncParametersList16 = [(itemIds: [String], shareId: String)]()

    public func deleteItems(itemIds: [String], shareId: String) async throws {
        invokedDeleteItemsItemIdsShareIdAsync16 = true
        invokedDeleteItemsItemIdsShareIdAsyncCount16 += 1
        invokedDeleteItemsItemIdsShareIdAsyncParameters16 = (itemIds, shareId)
        invokedDeleteItemsItemIdsShareIdAsyncParametersList16.append((itemIds, shareId))
        if let error = deleteItemsItemIdsShareIdThrowableError16 {
            throw error
        }
        closureDeleteItemsItemIdsShareIdAsync16()
    }
    // MARK: - removeAllItems
    public var removeAllItemsThrowableError17: Error?
    public var closureRemoveAllItemsAsync17: () -> () = {}
    public var invokedRemoveAllItemsAsync17 = false
    public var invokedRemoveAllItemsAsyncCount17 = 0

    public func removeAllItems() async throws {
        invokedRemoveAllItemsAsync17 = true
        invokedRemoveAllItemsAsyncCount17 += 1
        if let error = removeAllItemsThrowableError17 {
            throw error
        }
        closureRemoveAllItemsAsync17()
    }
    // MARK: - removeAllItemsShareId
    public var removeAllItemsShareIdThrowableError18: Error?
    public var closureRemoveAllItemsShareIdAsync18: () -> () = {}
    public var invokedRemoveAllItemsShareIdAsync18 = false
    public var invokedRemoveAllItemsShareIdAsyncCount18 = 0
    public var invokedRemoveAllItemsShareIdAsyncParameters18: (shareId: String, Void)?
    public var invokedRemoveAllItemsShareIdAsyncParametersList18 = [(shareId: String, Void)]()

    public func removeAllItems(shareId: String) async throws {
        invokedRemoveAllItemsShareIdAsync18 = true
        invokedRemoveAllItemsShareIdAsyncCount18 += 1
        invokedRemoveAllItemsShareIdAsyncParameters18 = (shareId, ())
        invokedRemoveAllItemsShareIdAsyncParametersList18.append((shareId, ()))
        if let error = removeAllItemsShareIdThrowableError18 {
            throw error
        }
        closureRemoveAllItemsShareIdAsync18()
    }
    // MARK: - removeAllItemsUserId
    public var removeAllItemsUserIdThrowableError19: Error?
    public var closureRemoveAllItemsUserIdAsync19: () -> () = {}
    public var invokedRemoveAllItemsUserIdAsync19 = false
    public var invokedRemoveAllItemsUserIdAsyncCount19 = 0
    public var invokedRemoveAllItemsUserIdAsyncParameters19: (userId: String, Void)?
    public var invokedRemoveAllItemsUserIdAsyncParametersList19 = [(userId: String, Void)]()

    public func removeAllItems(userId: String) async throws {
        invokedRemoveAllItemsUserIdAsync19 = true
        invokedRemoveAllItemsUserIdAsyncCount19 += 1
        invokedRemoveAllItemsUserIdAsyncParameters19 = (userId, ())
        invokedRemoveAllItemsUserIdAsyncParametersList19.append((userId, ()))
        if let error = removeAllItemsUserIdThrowableError19 {
            throw error
        }
        closureRemoveAllItemsUserIdAsync19()
    }
    // MARK: - getActiveLogInItems
    public var getActiveLogInItemsUserIdThrowableError20: Error?
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
        if let error = getActiveLogInItemsUserIdThrowableError20 {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
    // MARK: - getItemsItems
    public var getItemsForThrowableError21: Error?
    public var closureGetItemsItemsAsync21: () -> () = {}
    public var invokedGetItemsItemsAsync21 = false
    public var invokedGetItemsItemsAsyncCount21 = 0
    public var invokedGetItemsItemsAsyncParameters21: (items: [any ItemIdentifiable], Void)?
    public var invokedGetItemsItemsAsyncParametersList21 = [(items: [any ItemIdentifiable], Void)]()
    public var stubbedGetItemsItemsAsyncResult21: [SymmetricallyEncryptedItem]!

    public func getItems(for items: [any ItemIdentifiable]) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsItemsAsync21 = true
        invokedGetItemsItemsAsyncCount21 += 1
        invokedGetItemsItemsAsyncParameters21 = (items, ())
        invokedGetItemsItemsAsyncParametersList21.append((items, ()))
        if let error = getItemsForThrowableError21 {
            throw error
        }
        closureGetItemsItemsAsync21()
        return stubbedGetItemsItemsAsyncResult21
    }
}
