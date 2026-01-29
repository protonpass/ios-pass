// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
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
        if let error = getItemsShareIdStateThrowableError4 {
            throw error
        }
        closureGetItemsShareIdStateAsync4()
        return stubbedGetItemsShareIdStateAsyncResult4
    }
    // MARK: - getItemsShareIdFolderIdState
    public var getItemsShareIdFolderIdStateThrowableError5: Error?
    public var closureGetItemsShareIdFolderIdStateAsync5: () -> () = {}
    public var invokedGetItemsShareIdFolderIdStateAsync5 = false
    public var invokedGetItemsShareIdFolderIdStateAsyncCount5 = 0
    public var invokedGetItemsShareIdFolderIdStateAsyncParameters5: (shareId: String, folderId: String, state: ItemState)?
    public var invokedGetItemsShareIdFolderIdStateAsyncParametersList5 = [(shareId: String, folderId: String, state: ItemState)]()
    public var stubbedGetItemsShareIdFolderIdStateAsyncResult5: [SymmetricallyEncryptedItem]!

    public func getItems(shareId: String, folderId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsShareIdFolderIdStateAsync5 = true
        invokedGetItemsShareIdFolderIdStateAsyncCount5 += 1
        invokedGetItemsShareIdFolderIdStateAsyncParameters5 = (shareId, folderId, state)
        if let error = getItemsShareIdFolderIdStateThrowableError5 {
            throw error
        }
        closureGetItemsShareIdFolderIdStateAsync5()
        return stubbedGetItemsShareIdFolderIdStateAsyncResult5
    }
    // MARK: - getItemsIds
    public var getItemsThrowableError6: Error?
    public var closureGetItemsIdsAsync6: () -> () = {}
    public var invokedGetItemsIdsAsync6 = false
    public var invokedGetItemsIdsAsyncCount6 = 0
    public var invokedGetItemsIdsAsyncParameters6: (ids: [any ItemIdentifiable], Void)?
    public var invokedGetItemsIdsAsyncParametersList6 = [(ids: [any ItemIdentifiable], Void)]()
    public var stubbedGetItemsIdsAsyncResult6: [SymmetricallyEncryptedItem]!

    public func getItems(_ ids: [any ItemIdentifiable]) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsIdsAsync6 = true
        invokedGetItemsIdsAsyncCount6 += 1
        invokedGetItemsIdsAsyncParameters6 = (ids, ())
        if let error = getItemsThrowableError6 {
            throw error
        }
        closureGetItemsIdsAsync6()
        return stubbedGetItemsIdsAsyncResult6
    }
    // MARK: - getItem
    public var getItemShareIdItemIdThrowableError7: Error?
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
        if let error = getItemShareIdItemIdThrowableError7 {
            throw error
        }
        closureGetItem()
        return stubbedGetItemResult
    }
    // MARK: - getAliasItem
    public var getAliasItemEmailShareIdThrowableError8: Error?
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
        if let error = getAliasItemEmailShareIdThrowableError8 {
            throw error
        }
        closureGetAliasItem()
        return stubbedGetAliasItemResult
    }
    // MARK: - getItemCount
    public var getItemCountShareIdThrowableError9: Error?
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
        if let error = getItemCountShareIdThrowableError9 {
            throw error
        }
        closureGetItemCount()
        return stubbedGetItemCountResult
    }
    // MARK: - getAliasCount
    public var getAliasCountUserIdThrowableError10: Error?
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
        if let error = getAliasCountUserIdThrowableError10 {
            throw error
        }
        closureGetAliasCount()
        return stubbedGetAliasCountResult
    }
    // MARK: - getUnsyncedSimpleLoginNoteAliases
    public var getUnsyncedSimpleLoginNoteAliasesUserIdThrowableError11: Error?
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
        if let error = getUnsyncedSimpleLoginNoteAliasesUserIdThrowableError11 {
            throw error
        }
        closureGetUnsyncedSimpleLoginNoteAliases()
        return stubbedGetUnsyncedSimpleLoginNoteAliasesResult
    }
    // MARK: - updateCachedAliasInfo
    public var updateCachedAliasInfoItemsAliasesThrowableError12: Error?
    public var closureUpdateCachedAliasInfo: () -> () = {}
    public var invokedUpdateCachedAliasInfofunction = false
    public var invokedUpdateCachedAliasInfoCount = 0
    public var invokedUpdateCachedAliasInfoParameters: (items: [SymmetricallyEncryptedItem], aliases: [SymmetricallyEncryptedAlias])?
    public var invokedUpdateCachedAliasInfoParametersList = [(items: [SymmetricallyEncryptedItem], aliases: [SymmetricallyEncryptedAlias])]()

    public func updateCachedAliasInfo(items: [SymmetricallyEncryptedItem], aliases: [SymmetricallyEncryptedAlias]) async throws {
        invokedUpdateCachedAliasInfofunction = true
        invokedUpdateCachedAliasInfoCount += 1
        invokedUpdateCachedAliasInfoParameters = (items, aliases)
        if let error = updateCachedAliasInfoItemsAliasesThrowableError12 {
            throw error
        }
        closureUpdateCachedAliasInfo()
    }
    // MARK: - upsertItemsItems
    public var upsertItemsThrowableError13: Error?
    public var closureUpsertItemsItemsAsync13: () -> () = {}
    public var invokedUpsertItemsItemsAsync13 = false
    public var invokedUpsertItemsItemsAsyncCount13 = 0
    public var invokedUpsertItemsItemsAsyncParameters13: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUpsertItemsItemsAsyncParametersList13 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUpsertItemsItemsAsync13 = true
        invokedUpsertItemsItemsAsyncCount13 += 1
        invokedUpsertItemsItemsAsyncParameters13 = (items, ())
        if let error = upsertItemsThrowableError13 {
            throw error
        }
        closureUpsertItemsItemsAsync13()
    }
    // MARK: - upsertItemsItemsModifiedItems
    public var upsertItemsModifiedItemsThrowableError14: Error?
    public var closureUpsertItemsItemsModifiedItemsAsync14: () -> () = {}
    public var invokedUpsertItemsItemsModifiedItemsAsync14 = false
    public var invokedUpsertItemsItemsModifiedItemsAsyncCount14 = 0
    public var invokedUpsertItemsItemsModifiedItemsAsyncParameters14: (items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])?
    public var invokedUpsertItemsItemsModifiedItemsAsyncParametersList14 = [(items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem]) async throws {
        invokedUpsertItemsItemsModifiedItemsAsync14 = true
        invokedUpsertItemsItemsModifiedItemsAsyncCount14 += 1
        invokedUpsertItemsItemsModifiedItemsAsyncParameters14 = (items, modifiedItems)
        if let error = upsertItemsModifiedItemsThrowableError14 {
            throw error
        }
        closureUpsertItemsItemsModifiedItemsAsync14()
    }
    // MARK: - update
    public var updateLastUseItemsShareIdThrowableError15: Error?
    public var closureUpdate: () -> () = {}
    public var invokedUpdatefunction = false
    public var invokedUpdateCount = 0
    public var invokedUpdateParameters: (lastUseItems: [LastUseItem], shareId: String)?
    public var invokedUpdateParametersList = [(lastUseItems: [LastUseItem], shareId: String)]()

    public func update(lastUseItems: [LastUseItem], shareId: String) async throws {
        invokedUpdatefunction = true
        invokedUpdateCount += 1
        invokedUpdateParameters = (lastUseItems, shareId)
        if let error = updateLastUseItemsShareIdThrowableError15 {
            throw error
        }
        closureUpdate()
    }
    // MARK: - deleteItemsItems
    public var deleteItemsThrowableError16: Error?
    public var closureDeleteItemsItemsAsync16: () -> () = {}
    public var invokedDeleteItemsItemsAsync16 = false
    public var invokedDeleteItemsItemsAsyncCount16 = 0
    public var invokedDeleteItemsItemsAsyncParameters16: (items: [any ItemIdentifiable], Void)?
    public var invokedDeleteItemsItemsAsyncParametersList16 = [(items: [any ItemIdentifiable], Void)]()

    public func deleteItems(_ items: [any ItemIdentifiable]) async throws {
        invokedDeleteItemsItemsAsync16 = true
        invokedDeleteItemsItemsAsyncCount16 += 1
        invokedDeleteItemsItemsAsyncParameters16 = (items, ())
        if let error = deleteItemsThrowableError16 {
            throw error
        }
        closureDeleteItemsItemsAsync16()
    }
    // MARK: - deleteItemsItemIdsShareId
    public var deleteItemsItemIdsShareIdThrowableError17: Error?
    public var closureDeleteItemsItemIdsShareIdAsync17: () -> () = {}
    public var invokedDeleteItemsItemIdsShareIdAsync17 = false
    public var invokedDeleteItemsItemIdsShareIdAsyncCount17 = 0
    public var invokedDeleteItemsItemIdsShareIdAsyncParameters17: (itemIds: [String], shareId: String)?
    public var invokedDeleteItemsItemIdsShareIdAsyncParametersList17 = [(itemIds: [String], shareId: String)]()

    public func deleteItems(itemIds: [String], shareId: String) async throws {
        invokedDeleteItemsItemIdsShareIdAsync17 = true
        invokedDeleteItemsItemIdsShareIdAsyncCount17 += 1
        invokedDeleteItemsItemIdsShareIdAsyncParameters17 = (itemIds, shareId)
        if let error = deleteItemsItemIdsShareIdThrowableError17 {
            throw error
        }
        closureDeleteItemsItemIdsShareIdAsync17()
    }
    // MARK: - removeAllItems
    public var removeAllItemsThrowableError18: Error?
    public var closureRemoveAllItemsAsync18: () -> () = {}
    public var invokedRemoveAllItemsAsync18 = false
    public var invokedRemoveAllItemsAsyncCount18 = 0

    public func removeAllItems() async throws {
        invokedRemoveAllItemsAsync18 = true
        invokedRemoveAllItemsAsyncCount18 += 1
        if let error = removeAllItemsThrowableError18 {
            throw error
        }
        closureRemoveAllItemsAsync18()
    }
    // MARK: - removeAllItemsShareId
    public var removeAllItemsShareIdThrowableError19: Error?
    public var closureRemoveAllItemsShareIdAsync19: () -> () = {}
    public var invokedRemoveAllItemsShareIdAsync19 = false
    public var invokedRemoveAllItemsShareIdAsyncCount19 = 0
    public var invokedRemoveAllItemsShareIdAsyncParameters19: (shareId: String, Void)?
    public var invokedRemoveAllItemsShareIdAsyncParametersList19 = [(shareId: String, Void)]()

    public func removeAllItems(shareId: String) async throws {
        invokedRemoveAllItemsShareIdAsync19 = true
        invokedRemoveAllItemsShareIdAsyncCount19 += 1
        invokedRemoveAllItemsShareIdAsyncParameters19 = (shareId, ())
        if let error = removeAllItemsShareIdThrowableError19 {
            throw error
        }
        closureRemoveAllItemsShareIdAsync19()
    }
    // MARK: - removeAllItemsUserId
    public var removeAllItemsUserIdThrowableError20: Error?
    public var closureRemoveAllItemsUserIdAsync20: () -> () = {}
    public var invokedRemoveAllItemsUserIdAsync20 = false
    public var invokedRemoveAllItemsUserIdAsyncCount20 = 0
    public var invokedRemoveAllItemsUserIdAsyncParameters20: (userId: String, Void)?
    public var invokedRemoveAllItemsUserIdAsyncParametersList20 = [(userId: String, Void)]()

    public func removeAllItems(userId: String) async throws {
        invokedRemoveAllItemsUserIdAsync20 = true
        invokedRemoveAllItemsUserIdAsyncCount20 += 1
        invokedRemoveAllItemsUserIdAsyncParameters20 = (userId, ())
        if let error = removeAllItemsUserIdThrowableError20 {
            throw error
        }
        closureRemoveAllItemsUserIdAsync20()
    }
    // MARK: - getActiveLogInItems
    public var getActiveLogInItemsUserIdThrowableError21: Error?
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
        if let error = getActiveLogInItemsUserIdThrowableError21 {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
    // MARK: - getItemsItems
    public var getItemsForThrowableError22: Error?
    public var closureGetItemsItemsAsync22: () -> () = {}
    public var invokedGetItemsItemsAsync22 = false
    public var invokedGetItemsItemsAsyncCount22 = 0
    public var invokedGetItemsItemsAsyncParameters22: (items: [any ItemIdentifiable], Void)?
    public var invokedGetItemsItemsAsyncParametersList22 = [(items: [any ItemIdentifiable], Void)]()
    public var stubbedGetItemsItemsAsyncResult22: [SymmetricallyEncryptedItem]!

    public func getItems(for items: [any ItemIdentifiable]) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsItemsAsync22 = true
        invokedGetItemsItemsAsyncCount22 += 1
        invokedGetItemsItemsAsyncParameters22 = (items, ())
        if let error = getItemsForThrowableError22 {
            throw error
        }
        closureGetItemsItemsAsync22()
        return stubbedGetItemsItemsAsyncResult22
    }
}
