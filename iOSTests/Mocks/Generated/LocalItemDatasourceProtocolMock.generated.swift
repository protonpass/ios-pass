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
// swiftlint:disable all

@testable import Client
import CoreData
import Entities

final class LocalItemDatasourceProtocolMock: @unchecked Sendable, LocalItemDatasourceProtocol {
    // MARK: - getAllItems
    var getAllItemsThrowableError: Error?
    var closureGetAllItems: () -> () = {}
    var invokedGetAllItems = false
    var invokedGetAllItemsCount = 0
    var stubbedGetAllItemsResult: [SymmetricallyEncryptedItem]!

    func getAllItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetAllItems = true
        invokedGetAllItemsCount += 1
        if let error = getAllItemsThrowableError {
            throw error
        }
        closureGetAllItems()
        return stubbedGetAllItemsResult
    }
    // MARK: - getItemsState
    var getItemsStateThrowableError: Error?
    var closureGetItemsState: () -> () = {}
    var invokedGetItemsState = false
    var invokedGetItemsStateCount = 0
    var invokedGetItemsStateParameters: (state: ItemState, Void)?
    var invokedGetItemsStateParametersList = [(state: ItemState, Void)]()
    var stubbedGetItemsStateResult: [SymmetricallyEncryptedItem]!

    func getItems(state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsState = true
        invokedGetItemsStateCount += 1
        invokedGetItemsStateParameters = (state, ())
        invokedGetItemsStateParametersList.append((state, ()))
        if let error = getItemsStateThrowableError {
            throw error
        }
        closureGetItemsState()
        return stubbedGetItemsItemStateResult
    }
    // MARK: - getItem
    var getItemShareIdItemIdThrowableError: Error?
    var closureGetItem: () -> () = {}
    var invokedGetItem = false
    var invokedGetItemCount = 0
    var invokedGetItemParameters: (shareId: String, itemId: String)?
    var invokedGetItemParametersList = [(shareId: String, itemId: String)]()
    var stubbedGetItemResult: SymmetricallyEncryptedItem?

    func getItem(shareId: String, itemId: String) async throws -> SymmetricallyEncryptedItem? {
        invokedGetItem = true
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
    var getAliasItemEmailThrowableError: Error?
    var closureGetAliasItem: () -> () = {}
    var invokedGetAliasItem = false
    var invokedGetAliasItemCount = 0
    var invokedGetAliasItemParameters: (email: String, Void)?
    var invokedGetAliasItemParametersList = [(email: String, Void)]()
    var stubbedGetAliasItemResult: SymmetricallyEncryptedItem?

    func getAliasItem(email: String) async throws -> SymmetricallyEncryptedItem? {
        invokedGetAliasItem = true
        invokedGetAliasItemCount += 1
        invokedGetAliasItemParameters = (email, ())
        invokedGetAliasItemParametersList.append((email, ()))
        if let error = getAliasItemEmailThrowableError {
            throw error
        }
        closureGetAliasItem()
        return stubbedGetAliasItemResult
    }
    // MARK: - getItemsShareIdState
    var getItemsShareIdStateThrowableError: Error?
    var closureGetItemsShareIdState: () -> () = {}
    var invokedGetItemsShareIdState = false
    var invokedGetItemsShareIdStateCount = 0
    var invokedGetItemsShareIdStateParameters: (shareId: String, state: ItemState)?
    var invokedGetItemsShareIdStateParametersList = [(shareId: String, state: ItemState)]()
    var stubbedGetItemsShareIdStateResult: [SymmetricallyEncryptedItem]!

    func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsShareIdState = true
        invokedGetItemsShareIdStateCount += 1
        invokedGetItemsShareIdStateParameters = (shareId, state)
        invokedGetItemsShareIdStateParametersList.append((shareId, state))
        if let error = getItemsShareIdStateThrowableError {
            throw error
        }
        closureGetItemsShareIdState()
        return stubbedGetItemsStringItemStateResult
    }
    // MARK: - getItemCount
    var getItemCountShareIdThrowableError: Error?
    var closureGetItemCount: () -> () = {}
    var invokedGetItemCount = false
    var invokedGetItemCountCount = 0
    var invokedGetItemCountParameters: (shareId: String, Void)?
    var invokedGetItemCountParametersList = [(shareId: String, Void)]()
    var stubbedGetItemCountResult: Int!

    func getItemCount(shareId: String) async throws -> Int {
        invokedGetItemCount = true
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
    var upsertItemsThrowableError: Error?
    var closureUpsertItemsItems: () -> () = {}
    var invokedUpsertItemsItems = false
    var invokedUpsertItemsItemsCount = 0
    var invokedUpsertItemsItemsParameters: (items: [SymmetricallyEncryptedItem], Void)?
    var invokedUpsertItemsItemsParametersList = [(items: [SymmetricallyEncryptedItem], Void)]()

    func upsertItems(_ items: [SymmetricallyEncryptedItem]) async throws {
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
    var upsertItemsModifiedItemsThrowableError: Error?
    var closureUpsertItemsItemsModifiedItems: () -> () = {}
    var invokedUpsertItemsItemsModifiedItems = false
    var invokedUpsertItemsItemsModifiedItemsCount = 0
    var invokedUpsertItemsItemsModifiedItemsParameters: (items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])?
    var invokedUpsertItemsItemsModifiedItemsParametersList = [(items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem])]()

    func upsertItems(_ items: [SymmetricallyEncryptedItem], modifiedItems: [ModifiedItem]) async throws {
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
    var updateLastUseItemsShareIdThrowableError: Error?
    var closureUpdate: () -> () = {}
    var invokedUpdate = false
    var invokedUpdateCount = 0
    var invokedUpdateParameters: (lastUseItems: [LastUseItem], shareId: String)?
    var invokedUpdateParametersList = [(lastUseItems: [LastUseItem], shareId: String)]()

    func update(lastUseItems: [LastUseItem], shareId: String) async throws {
        invokedUpdate = true
        invokedUpdateCount += 1
        invokedUpdateParameters = (lastUseItems, shareId)
        invokedUpdateParametersList.append((lastUseItems, shareId))
        if let error = updateLastUseItemsShareIdThrowableError {
            throw error
        }
        closureUpdate()
    }
    // MARK: - deleteItemsItems
    var deleteItemsThrowableError: Error?
    var closureDeleteItemsItems: () -> () = {}
    var invokedDeleteItemsItems = false
    var invokedDeleteItemsItemsCount = 0
    var invokedDeleteItemsItemsParameters: (items: [SymmetricallyEncryptedItem], Void)?
    var invokedDeleteItemsItemsParametersList = [(items: [SymmetricallyEncryptedItem], Void)]()

    func deleteItems(_ items: [SymmetricallyEncryptedItem]) async throws {
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
    var deleteItemsItemIdsShareIdThrowableError: Error?
    var closureDeleteItemsItemIdsShareId: () -> () = {}
    var invokedDeleteItemsItemIdsShareId = false
    var invokedDeleteItemsItemIdsShareIdCount = 0
    var invokedDeleteItemsItemIdsShareIdParameters: (itemIds: [String], shareId: String)?
    var invokedDeleteItemsItemIdsShareIdParametersList = [(itemIds: [String], shareId: String)]()

    func deleteItems(itemIds: [String], shareId: String) async throws {
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
    var removeAllItemsThrowableError: Error?
    var closureRemoveAllItems: () -> () = {}
    var invokedRemoveAllItems = false
    var invokedRemoveAllItemsCount = 0

    func removeAllItems() async throws {
        invokedRemoveAllItems = true
        invokedRemoveAllItemsCount += 1
        if let error = removeAllItemsThrowableError {
            throw error
        }
        closureRemoveAllItems()
    }
    // MARK: - removeAllItemsShareId
    var removeAllItemsShareIdThrowableError: Error?
    var closureRemoveAllItemsShareId: () -> () = {}
    var invokedRemoveAllItemsShareId = false
    var invokedRemoveAllItemsShareIdCount = 0
    var invokedRemoveAllItemsShareIdParameters: (shareId: String, Void)?
    var invokedRemoveAllItemsShareIdParametersList = [(shareId: String, Void)]()

    func removeAllItems(shareId: String) async throws {
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
    var getActiveLogInItemsThrowableError: Error?
    var closureGetActiveLogInItems: () -> () = {}
    var invokedGetActiveLogInItems = false
    var invokedGetActiveLogInItemsCount = 0
    var stubbedGetActiveLogInItemsResult: [SymmetricallyEncryptedItem]!

    func getActiveLogInItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetActiveLogInItems = true
        invokedGetActiveLogInItemsCount += 1
        if let error = getActiveLogInItemsThrowableError {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
}
