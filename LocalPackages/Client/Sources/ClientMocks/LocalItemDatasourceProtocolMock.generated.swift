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

@testable import Client
import CoreData
import Entities

public final class LocalItemDatasourceProtocolMock: @unchecked Sendable, LocalItemDatasourceProtocol {

    public init() {}

    // MARK: - getAllItems
    public var getAllItemsThrowableError: Error?
    public var closureGetAllItems: () -> () = {}
    public var invokedGetAllItemsfunction = false
    public var invokedGetAllItemsCount = 0
    public var stubbedGetAllItemsResult: [SymmetricallyEncryptedItem]!

    public func getAllItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetAllItemsfunction = true
        invokedGetAllItemsCount += 1
        if let error = getAllItemsThrowableError {
            throw error
        }
        closureGetAllItems()
        return stubbedGetAllItemsResult
    }
    // MARK: - getItemsState
    public var getItemsStateThrowableError: Error?
    public var closureGetItemsState: () -> () = {}
    public var invokedGetItemsState = false
    public var invokedGetItemsStateCount = 0
    public var invokedGetItemsStateParameters: (state: ItemState, Void)?
    public var invokedGetItemsStateParametersList = [(state: ItemState, Void)]()
    public var stubbedGetItemsStateResult: [SymmetricallyEncryptedItem]!

    public func getItems(state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsState = true
        invokedGetItemsStateCount += 1
        invokedGetItemsStateParameters = (state, ())
        invokedGetItemsStateParametersList.append((state, ()))
        if let error = getItemsStateThrowableError {
            throw error
        }
        closureGetItemsState()
        return stubbedGetItemsStateResult
    }
    // MARK: - getItemsShareIdState
    public var getItemsShareIdStateThrowableError: Error?
    public var closureGetItemsShareIdState: () -> () = {}
    public var invokedGetItemsShareIdState = false
    public var invokedGetItemsShareIdStateCount = 0
    public var invokedGetItemsShareIdStateParameters: (shareId: String, state: ItemState)?
    public var invokedGetItemsShareIdStateParametersList = [(shareId: String, state: ItemState)]()
    public var stubbedGetItemsShareIdStateResult: [SymmetricallyEncryptedItem]!

    public func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsShareIdState = true
        invokedGetItemsShareIdStateCount += 1
        invokedGetItemsShareIdStateParameters = (shareId, state)
        invokedGetItemsShareIdStateParametersList.append((shareId, state))
        if let error = getItemsShareIdStateThrowableError {
            throw error
        }
        closureGetItemsShareIdState()
        return stubbedGetItemsShareIdStateResult
    }
    // MARK: - getItem
    public var getItemShareIdItemIdThrowableError: Error?
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
        if let error = getItemShareIdItemIdThrowableError {
            throw error
        }
        closureGetItem()
        return stubbedGetItemResult
    }
    // MARK: - getAliasItem
    public var getAliasItemEmailThrowableError: Error?
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
        if let error = getAliasItemEmailThrowableError {
            throw error
        }
        closureGetAliasItem()
        return stubbedGetAliasItemResult
    }
    // MARK: - getItemCount
    public var getItemCountShareIdThrowableError: Error?
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
        if let error = getItemCountShareIdThrowableError {
            throw error
        }
        closureGetItemCount()
        return stubbedGetItemCountResult
    }
    // MARK: - upsertItemsItems
    public var upsertItemsThrowableError: Error?
    public var closureUpsertItemsItems: () -> () = {}
    public var invokedUpsertItemsItems = false
    public var invokedUpsertItemsItemsCount = 0
    public var invokedUpsertItemsItemsParameters: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUpsertItemsItemsParametersList = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUpsertItemsItems = true
        invokedUpsertItemsItemsCount += 1
        invokedUpsertItemsItemsParameters = (items, ())
        invokedUpsertItemsItemsParametersList.append((items, ()))
        if let error = upsertItemsThrowableError {
            throw error
        }
        closureUpsertItemsItems()
    }
    // MARK: - upsertItemsItemsModifiedItems
    public var upsertItemsModifiedItemsThrowableError: Error?
    public var closureUpsertItemsItemsModifiedItems: () -> () = {}
    public var invokedUpsertItemsItemsModifiedItems = false
    public var invokedUpsertItemsItemsModifiedItemsCount = 0
    public var invokedUpsertItemsItemsModifiedItemsParameters: (items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])?
    public var invokedUpsertItemsItemsModifiedItemsParametersList = [(items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])]()

    public func upsertItems(_ items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem]) async throws {
        invokedUpsertItemsItemsModifiedItems = true
        invokedUpsertItemsItemsModifiedItemsCount += 1
        invokedUpsertItemsItemsModifiedItemsParameters = (items, modifiedItems)
        invokedUpsertItemsItemsModifiedItemsParametersList.append((items, modifiedItems))
        if let error = upsertItemsModifiedItemsThrowableError {
            throw error
        }
        closureUpsertItemsItemsModifiedItems()
    }
    // MARK: - update
    public var updateLastUseItemsShareIdThrowableError: Error?
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
        if let error = updateLastUseItemsShareIdThrowableError {
            throw error
        }
        closureUpdate()
    }
    // MARK: - deleteItemsItems
    public var deleteItemsThrowableError: Error?
    public var closureDeleteItemsItems: () -> () = {}
    public var invokedDeleteItemsItems = false
    public var invokedDeleteItemsItemsCount = 0
    public var invokedDeleteItemsItemsParameters: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedDeleteItemsItemsParametersList = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func deleteItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedDeleteItemsItems = true
        invokedDeleteItemsItemsCount += 1
        invokedDeleteItemsItemsParameters = (items, ())
        invokedDeleteItemsItemsParametersList.append((items, ()))
        if let error = deleteItemsThrowableError {
            throw error
        }
        closureDeleteItemsItems()
    }
    // MARK: - deleteItemsItemIdsShareId
    public var deleteItemsItemIdsShareIdThrowableError: Error?
    public var closureDeleteItemsItemIdsShareId: () -> () = {}
    public var invokedDeleteItemsItemIdsShareId = false
    public var invokedDeleteItemsItemIdsShareIdCount = 0
    public var invokedDeleteItemsItemIdsShareIdParameters: (itemIds: [String], shareId: String)?
    public var invokedDeleteItemsItemIdsShareIdParametersList = [(itemIds: [String], shareId: String)]()

    public func deleteItems(itemIds: [String], shareId: String) async throws {
        invokedDeleteItemsItemIdsShareId = true
        invokedDeleteItemsItemIdsShareIdCount += 1
        invokedDeleteItemsItemIdsShareIdParameters = (itemIds, shareId)
        invokedDeleteItemsItemIdsShareIdParametersList.append((itemIds, shareId))
        if let error = deleteItemsItemIdsShareIdThrowableError {
            throw error
        }
        closureDeleteItemsItemIdsShareId()
    }
    // MARK: - removeAllItems
    public var removeAllItemsThrowableError: Error?
    public var closureRemoveAllItems: () -> () = {}
    public var invokedRemoveAllItems = false
    public var invokedRemoveAllItemsCount = 0

    public func removeAllItems() async throws {
        invokedRemoveAllItems = true
        invokedRemoveAllItemsCount += 1
        if let error = removeAllItemsThrowableError {
            throw error
        }
        closureRemoveAllItems()
    }
    // MARK: - removeAllItemsShareId
    public var removeAllItemsShareIdThrowableError: Error?
    public var closureRemoveAllItemsShareId: () -> () = {}
    public var invokedRemoveAllItemsShareId = false
    public var invokedRemoveAllItemsShareIdCount = 0
    public var invokedRemoveAllItemsShareIdParameters: (shareId: String, Void)?
    public var invokedRemoveAllItemsShareIdParametersList = [(shareId: String, Void)]()

    public func removeAllItems(shareId: String) async throws {
        invokedRemoveAllItemsShareId = true
        invokedRemoveAllItemsShareIdCount += 1
        invokedRemoveAllItemsShareIdParameters = (shareId, ())
        invokedRemoveAllItemsShareIdParametersList.append((shareId, ()))
        if let error = removeAllItemsShareIdThrowableError {
            throw error
        }
        closureRemoveAllItemsShareId()
    }
    // MARK: - getActiveLogInItems
    public var getActiveLogInItemsThrowableError: Error?
    public var closureGetActiveLogInItems: () -> () = {}
    public var invokedGetActiveLogInItemsfunction = false
    public var invokedGetActiveLogInItemsCount = 0
    public var stubbedGetActiveLogInItemsResult: [SymmetricallyEncryptedItem]!

    public func getActiveLogInItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetActiveLogInItemsfunction = true
        invokedGetActiveLogInItemsCount += 1
        if let error = getActiveLogInItemsThrowableError {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
    // MARK: - getAllPinnedItems
    public var getAllPinnedItemsThrowableError: Error?
    public var closureGetAllPinnedItems: () -> () = {}
    public var invokedGetAllPinnedItemsfunction = false
    public var invokedGetAllPinnedItemsCount = 0
    public var stubbedGetAllPinnedItemsResult: [SymmetricallyEncryptedItem]!

    public func getAllPinnedItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetAllPinnedItemsfunction = true
        invokedGetAllPinnedItemsCount += 1
        if let error = getAllPinnedItemsThrowableError {
            throw error
        }
        closureGetAllPinnedItems()
        return stubbedGetAllPinnedItemsResult
    }
}
