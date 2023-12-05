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
import Combine
import Core
import CoreData
import CryptoKit
import Entities
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreServices

public final class ItemRepositoryProtocolMock: @unchecked Sendable, ItemRepositoryProtocol {

    public init() {}

    // MARK: - currentlyPinnedItems
    public var invokedCurrentlyPinnedItemsSetter = false
    public var invokedCurrentlyPinnedItemsSetterCount = 0
    public var invokedCurrentlyPinnedItems: CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never>?
    public var invokedCurrentlyPinnedItemsList = [CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never>?]()
    public var invokedCurrentlyPinnedItemsGetter = false
    public var invokedCurrentlyPinnedItemsGetterCount = 0
    public var stubbedCurrentlyPinnedItems: CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never>!
    public var currentlyPinnedItems: CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never> {
        set {
            invokedCurrentlyPinnedItemsSetter = true
            invokedCurrentlyPinnedItemsSetterCount += 1
            invokedCurrentlyPinnedItems = newValue
            invokedCurrentlyPinnedItemsList.append(newValue)
        } get {
            invokedCurrentlyPinnedItemsGetter = true
            invokedCurrentlyPinnedItemsGetterCount += 1
            return stubbedCurrentlyPinnedItems
        }
    }
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
    public var closureGetItemsStateAsync: () -> () = {}
    public var invokedGetItemsStateAsync = false
    public var invokedGetItemsStateAsyncCount = 0
    public var invokedGetItemsStateAsyncParameters: (state: ItemState, Void)?
    public var invokedGetItemsStateAsyncParametersList = [(state: ItemState, Void)]()
    public var stubbedGetItemsStateAsyncResult: [SymmetricallyEncryptedItem]!

    public func getItems(state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsStateAsync = true
        invokedGetItemsStateAsyncCount += 1
        invokedGetItemsStateAsyncParameters = (state, ())
        invokedGetItemsStateAsyncParametersList.append((state, ()))
        if let error = getItemsStateThrowableError {
            throw error
        }
        closureGetItemsStateAsync()
        return stubbedGetItemsStateAsyncResult
    }
    // MARK: - getItemsShareIdState
    public var getItemsShareIdStateThrowableError: Error?
    public var closureGetItemsShareIdStateAsync: () -> () = {}
    public var invokedGetItemsShareIdStateAsync = false
    public var invokedGetItemsShareIdStateAsyncCount = 0
    public var invokedGetItemsShareIdStateAsyncParameters: (shareId: String, state: ItemState)?
    public var invokedGetItemsShareIdStateAsyncParametersList = [(shareId: String, state: ItemState)]()
    public var stubbedGetItemsShareIdStateAsyncResult: [SymmetricallyEncryptedItem]!

    public func getItems(shareId: String, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsShareIdStateAsync = true
        invokedGetItemsShareIdStateAsyncCount += 1
        invokedGetItemsShareIdStateAsyncParameters = (shareId, state)
        invokedGetItemsShareIdStateAsyncParametersList.append((shareId, state))
        if let error = getItemsShareIdStateThrowableError {
            throw error
        }
        closureGetItemsShareIdStateAsync()
        return stubbedGetItemsShareIdStateAsyncResult
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
    // MARK: - getItemContent
    public var getItemContentShareIdItemIdThrowableError: Error?
    public var closureGetItemContent: () -> () = {}
    public var invokedGetItemContentfunction = false
    public var invokedGetItemContentCount = 0
    public var invokedGetItemContentParameters: (shareId: String, itemId: String)?
    public var invokedGetItemContentParametersList = [(shareId: String, itemId: String)]()
    public var stubbedGetItemContentResult: ItemContent?

    public func getItemContent(shareId: String, itemId: String) async throws -> ItemContent? {
        invokedGetItemContentfunction = true
        invokedGetItemContentCount += 1
        invokedGetItemContentParameters = (shareId, itemId)
        invokedGetItemContentParametersList.append((shareId, itemId))
        if let error = getItemContentShareIdItemIdThrowableError {
            throw error
        }
        closureGetItemContent()
        return stubbedGetItemContentResult
    }
    // MARK: - refreshItems
    public var refreshItemsShareIdEventStreamThrowableError: Error?
    public var closureRefreshItems: () -> () = {}
    public var invokedRefreshItemsfunction = false
    public var invokedRefreshItemsCount = 0
    public var invokedRefreshItemsParameters: (shareId: String, eventStream: VaultSyncEventStream?)?
    public var invokedRefreshItemsParametersList = [(shareId: String, eventStream: VaultSyncEventStream?)]()

    public func refreshItems(shareId: String, eventStream: VaultSyncEventStream?) async throws {
        invokedRefreshItemsfunction = true
        invokedRefreshItemsCount += 1
        invokedRefreshItemsParameters = (shareId, eventStream)
        invokedRefreshItemsParametersList.append((shareId, eventStream))
        if let error = refreshItemsShareIdEventStreamThrowableError {
            throw error
        }
        closureRefreshItems()
    }
    // MARK: - createItem
    public var createItemItemContentShareIdThrowableError: Error?
    public var closureCreateItem: () -> () = {}
    public var invokedCreateItemfunction = false
    public var invokedCreateItemCount = 0
    public var invokedCreateItemParameters: (itemContent: ProtobufableItemContentProtocol, shareId: String)?
    public var invokedCreateItemParametersList = [(itemContent: ProtobufableItemContentProtocol, shareId: String)]()
    public var stubbedCreateItemResult: SymmetricallyEncryptedItem!

    public func createItem(itemContent: ProtobufableItemContentProtocol, shareId: String) async throws -> SymmetricallyEncryptedItem {
        invokedCreateItemfunction = true
        invokedCreateItemCount += 1
        invokedCreateItemParameters = (itemContent, shareId)
        invokedCreateItemParametersList.append((itemContent, shareId))
        if let error = createItemItemContentShareIdThrowableError {
            throw error
        }
        closureCreateItem()
        return stubbedCreateItemResult
    }
    // MARK: - createAlias
    public var createAliasInfoItemContentShareIdThrowableError: Error?
    public var closureCreateAlias: () -> () = {}
    public var invokedCreateAliasfunction = false
    public var invokedCreateAliasCount = 0
    public var invokedCreateAliasParameters: (info: AliasCreationInfo, itemContent: ProtobufableItemContentProtocol, shareId: String)?
    public var invokedCreateAliasParametersList = [(info: AliasCreationInfo, itemContent: ProtobufableItemContentProtocol, shareId: String)]()
    public var stubbedCreateAliasResult: SymmetricallyEncryptedItem!

    public func createAlias(info: AliasCreationInfo, itemContent: ProtobufableItemContentProtocol, shareId: String) async throws -> SymmetricallyEncryptedItem {
        invokedCreateAliasfunction = true
        invokedCreateAliasCount += 1
        invokedCreateAliasParameters = (info, itemContent, shareId)
        invokedCreateAliasParametersList.append((info, itemContent, shareId))
        if let error = createAliasInfoItemContentShareIdThrowableError {
            throw error
        }
        closureCreateAlias()
        return stubbedCreateAliasResult
    }
    // MARK: - createAliasAndOtherItem
    public var createAliasAndOtherItemInfoAliasItemContentOtherItemContentShareIdThrowableError: Error?
    public var closureCreateAliasAndOtherItem: () -> () = {}
    public var invokedCreateAliasAndOtherItemfunction = false
    public var invokedCreateAliasAndOtherItemCount = 0
    public var invokedCreateAliasAndOtherItemParameters: (info: AliasCreationInfo, aliasItemContent: ProtobufableItemContentProtocol, otherItemContent: ProtobufableItemContentProtocol, shareId: String)?
    public var invokedCreateAliasAndOtherItemParametersList = [(info: AliasCreationInfo, aliasItemContent: ProtobufableItemContentProtocol, otherItemContent: ProtobufableItemContentProtocol, shareId: String)]()
    public var stubbedCreateAliasAndOtherItemResult: (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem)!

    public func createAliasAndOtherItem(info: AliasCreationInfo, aliasItemContent: ProtobufableItemContentProtocol, otherItemContent: ProtobufableItemContentProtocol, shareId: String) async throws -> (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem) {
        invokedCreateAliasAndOtherItemfunction = true
        invokedCreateAliasAndOtherItemCount += 1
        invokedCreateAliasAndOtherItemParameters = (info, aliasItemContent, otherItemContent, shareId)
        invokedCreateAliasAndOtherItemParametersList.append((info, aliasItemContent, otherItemContent, shareId))
        if let error = createAliasAndOtherItemInfoAliasItemContentOtherItemContentShareIdThrowableError {
            throw error
        }
        closureCreateAliasAndOtherItem()
        return stubbedCreateAliasAndOtherItemResult
    }
    // MARK: - trashItems
    public var trashItemsThrowableError: Error?
    public var closureTrashItems: () -> () = {}
    public var invokedTrashItemsfunction = false
    public var invokedTrashItemsCount = 0
    public var invokedTrashItemsParameters: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedTrashItemsParametersList = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedTrashItemsfunction = true
        invokedTrashItemsCount += 1
        invokedTrashItemsParameters = (items, ())
        invokedTrashItemsParametersList.append((items, ()))
        if let error = trashItemsThrowableError {
            throw error
        }
        closureTrashItems()
    }
    // MARK: - deleteAlias
    public var deleteAliasEmailThrowableError: Error?
    public var closureDeleteAlias: () -> () = {}
    public var invokedDeleteAliasfunction = false
    public var invokedDeleteAliasCount = 0
    public var invokedDeleteAliasParameters: (email: String, Void)?
    public var invokedDeleteAliasParametersList = [(email: String, Void)]()

    public func deleteAlias(email: String) async throws {
        invokedDeleteAliasfunction = true
        invokedDeleteAliasCount += 1
        invokedDeleteAliasParameters = (email, ())
        invokedDeleteAliasParametersList.append((email, ()))
        if let error = deleteAliasEmailThrowableError {
            throw error
        }
        closureDeleteAlias()
    }
    // MARK: - untrashItems
    public var untrashItemsThrowableError: Error?
    public var closureUntrashItems: () -> () = {}
    public var invokedUntrashItemsfunction = false
    public var invokedUntrashItemsCount = 0
    public var invokedUntrashItemsParameters: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUntrashItemsParametersList = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUntrashItemsfunction = true
        invokedUntrashItemsCount += 1
        invokedUntrashItemsParameters = (items, ())
        invokedUntrashItemsParametersList.append((items, ()))
        if let error = untrashItemsThrowableError {
            throw error
        }
        closureUntrashItems()
    }
    // MARK: - deleteItems
    public var deleteItemsSkipTrashThrowableError: Error?
    public var closureDeleteItems: () -> () = {}
    public var invokedDeleteItemsfunction = false
    public var invokedDeleteItemsCount = 0
    public var invokedDeleteItemsParameters: (items: [SymmetricallyEncryptedItem], skipTrash: Bool)?
    public var invokedDeleteItemsParametersList = [(items: [SymmetricallyEncryptedItem], skipTrash: Bool)]()

    public func deleteItems(_ items: [SymmetricallyEncryptedItem], skipTrash: Bool) async throws {
        invokedDeleteItemsfunction = true
        invokedDeleteItemsCount += 1
        invokedDeleteItemsParameters = (items, skipTrash)
        invokedDeleteItemsParametersList.append((items, skipTrash))
        if let error = deleteItemsSkipTrashThrowableError {
            throw error
        }
        closureDeleteItems()
    }
    // MARK: - updateItem
    public var updateItemOldItemNewItemContentShareIdThrowableError: Error?
    public var closureUpdateItem: () -> () = {}
    public var invokedUpdateItemfunction = false
    public var invokedUpdateItemCount = 0
    public var invokedUpdateItemParameters: (oldItem: ItemRevision, newItemContent: ProtobufableItemContentProtocol, shareId: String)?
    public var invokedUpdateItemParametersList = [(oldItem: ItemRevision, newItemContent: ProtobufableItemContentProtocol, shareId: String)]()

    public func updateItem(oldItem: ItemRevision, newItemContent: ProtobufableItemContentProtocol, shareId: String) async throws {
        invokedUpdateItemfunction = true
        invokedUpdateItemCount += 1
        invokedUpdateItemParameters = (oldItem, newItemContent, shareId)
        invokedUpdateItemParametersList.append((oldItem, newItemContent, shareId))
        if let error = updateItemOldItemNewItemContentShareIdThrowableError {
            throw error
        }
        closureUpdateItem()
    }
    // MARK: - upsertItems
    public var upsertItemsShareIdThrowableError: Error?
    public var closureUpsertItems: () -> () = {}
    public var invokedUpsertItemsfunction = false
    public var invokedUpsertItemsCount = 0
    public var invokedUpsertItemsParameters: (items: [ItemRevision], shareId: String)?
    public var invokedUpsertItemsParametersList = [(items: [ItemRevision], shareId: String)]()

    public func upsertItems(_ items: [ItemRevision], shareId: String) async throws {
        invokedUpsertItemsfunction = true
        invokedUpsertItemsCount += 1
        invokedUpsertItemsParameters = (items, shareId)
        invokedUpsertItemsParametersList.append((items, shareId))
        if let error = upsertItemsShareIdThrowableError {
            throw error
        }
        closureUpsertItems()
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
    // MARK: - updateLastUseTime
    public var updateLastUseTimeItemDateThrowableError: Error?
    public var closureUpdateLastUseTime: () -> () = {}
    public var invokedUpdateLastUseTimefunction = false
    public var invokedUpdateLastUseTimeCount = 0
    public var invokedUpdateLastUseTimeParameters: (item: any ItemIdentifiable, date: Date)?
    public var invokedUpdateLastUseTimeParametersList = [(item: any ItemIdentifiable, date: Date)]()

    public func updateLastUseTime(item: any ItemIdentifiable, date: Date) async throws {
        invokedUpdateLastUseTimefunction = true
        invokedUpdateLastUseTimeCount += 1
        invokedUpdateLastUseTimeParameters = (item, date)
        invokedUpdateLastUseTimeParametersList.append((item, date))
        if let error = updateLastUseTimeItemDateThrowableError {
            throw error
        }
        closureUpdateLastUseTime()
    }
    // MARK: - moveItemToShareId
    public var moveItemToShareIdThrowableError: Error?
    public var closureMoveItemToShareIdAsync: () -> () = {}
    public var invokedMoveItemToShareIdAsync = false
    public var invokedMoveItemToShareIdAsyncCount = 0
    public var invokedMoveItemToShareIdAsyncParameters: (item: any ItemIdentifiable, toShareId: String)?
    public var invokedMoveItemToShareIdAsyncParametersList = [(item: any ItemIdentifiable, toShareId: String)]()
    public var stubbedMoveItemToShareIdAsyncResult: SymmetricallyEncryptedItem!

    public func move(item: any ItemIdentifiable, toShareId: String) async throws -> SymmetricallyEncryptedItem {
        invokedMoveItemToShareIdAsync = true
        invokedMoveItemToShareIdAsyncCount += 1
        invokedMoveItemToShareIdAsyncParameters = (item, toShareId)
        invokedMoveItemToShareIdAsyncParametersList.append((item, toShareId))
        if let error = moveItemToShareIdThrowableError {
            throw error
        }
        closureMoveItemToShareIdAsync()
        return stubbedMoveItemToShareIdAsyncResult
    }
    // MARK: - moveOldEncryptedItemsToShareId
    public var moveOldEncryptedItemsToShareIdThrowableError: Error?
    public var closureMoveOldEncryptedItemsToShareIdAsync: () -> () = {}
    public var invokedMoveOldEncryptedItemsToShareIdAsync = false
    public var invokedMoveOldEncryptedItemsToShareIdAsyncCount = 0
    public var invokedMoveOldEncryptedItemsToShareIdAsyncParameters: (oldEncryptedItems: [SymmetricallyEncryptedItem], toShareId: String)?
    public var invokedMoveOldEncryptedItemsToShareIdAsyncParametersList = [(oldEncryptedItems: [SymmetricallyEncryptedItem], toShareId: String)]()
    public var stubbedMoveOldEncryptedItemsToShareIdAsyncResult: [SymmetricallyEncryptedItem]!

    public func move(oldEncryptedItems: [SymmetricallyEncryptedItem], toShareId: String) async throws -> [SymmetricallyEncryptedItem] {
        invokedMoveOldEncryptedItemsToShareIdAsync = true
        invokedMoveOldEncryptedItemsToShareIdAsyncCount += 1
        invokedMoveOldEncryptedItemsToShareIdAsyncParameters = (oldEncryptedItems, toShareId)
        invokedMoveOldEncryptedItemsToShareIdAsyncParametersList.append((oldEncryptedItems, toShareId))
        if let error = moveOldEncryptedItemsToShareIdThrowableError {
            throw error
        }
        closureMoveOldEncryptedItemsToShareIdAsync()
        return stubbedMoveOldEncryptedItemsToShareIdAsyncResult
    }
    // MARK: - moveCurrentShareIdToShareId
    public var moveCurrentShareIdToShareIdThrowableError: Error?
    public var closureMoveCurrentShareIdToShareIdAsync: () -> () = {}
    public var invokedMoveCurrentShareIdToShareIdAsync = false
    public var invokedMoveCurrentShareIdToShareIdAsyncCount = 0
    public var invokedMoveCurrentShareIdToShareIdAsyncParameters: (currentShareId: String, toShareId: String)?
    public var invokedMoveCurrentShareIdToShareIdAsyncParametersList = [(currentShareId: String, toShareId: String)]()
    public var stubbedMoveCurrentShareIdToShareIdAsyncResult: [SymmetricallyEncryptedItem]!

    public func move(currentShareId: String, toShareId: String) async throws -> [SymmetricallyEncryptedItem] {
        invokedMoveCurrentShareIdToShareIdAsync = true
        invokedMoveCurrentShareIdToShareIdAsyncCount += 1
        invokedMoveCurrentShareIdToShareIdAsyncParameters = (currentShareId, toShareId)
        invokedMoveCurrentShareIdToShareIdAsyncParametersList.append((currentShareId, toShareId))
        if let error = moveCurrentShareIdToShareIdThrowableError {
            throw error
        }
        closureMoveCurrentShareIdToShareIdAsync()
        return stubbedMoveCurrentShareIdToShareIdAsyncResult
    }
    // MARK: - deleteAllItemsLocally
    public var deleteAllItemsLocallyThrowableError: Error?
    public var closureDeleteAllItemsLocallyAsync: () -> () = {}
    public var invokedDeleteAllItemsLocallyAsync = false
    public var invokedDeleteAllItemsLocallyAsyncCount = 0

    public func deleteAllItemsLocally() async throws {
        invokedDeleteAllItemsLocallyAsync = true
        invokedDeleteAllItemsLocallyAsyncCount += 1
        if let error = deleteAllItemsLocallyThrowableError {
            throw error
        }
        closureDeleteAllItemsLocallyAsync()
    }
    // MARK: - deleteAllItemsLocallyShareId
    public var deleteAllItemsLocallyShareIdThrowableError: Error?
    public var closureDeleteAllItemsLocallyShareIdAsync: () -> () = {}
    public var invokedDeleteAllItemsLocallyShareIdAsync = false
    public var invokedDeleteAllItemsLocallyShareIdAsyncCount = 0
    public var invokedDeleteAllItemsLocallyShareIdAsyncParameters: (shareId: String, Void)?
    public var invokedDeleteAllItemsLocallyShareIdAsyncParametersList = [(shareId: String, Void)]()

    public func deleteAllItemsLocally(shareId: String) async throws {
        invokedDeleteAllItemsLocallyShareIdAsync = true
        invokedDeleteAllItemsLocallyShareIdAsyncCount += 1
        invokedDeleteAllItemsLocallyShareIdAsyncParameters = (shareId, ())
        invokedDeleteAllItemsLocallyShareIdAsyncParametersList.append((shareId, ()))
        if let error = deleteAllItemsLocallyShareIdThrowableError {
            throw error
        }
        closureDeleteAllItemsLocallyShareIdAsync()
    }
    // MARK: - deleteItemsLocally
    public var deleteItemsLocallyItemIdsShareIdThrowableError: Error?
    public var closureDeleteItemsLocally: () -> () = {}
    public var invokedDeleteItemsLocallyfunction = false
    public var invokedDeleteItemsLocallyCount = 0
    public var invokedDeleteItemsLocallyParameters: (itemIds: [String], shareId: String)?
    public var invokedDeleteItemsLocallyParametersList = [(itemIds: [String], shareId: String)]()

    public func deleteItemsLocally(itemIds: [String], shareId: String) async throws {
        invokedDeleteItemsLocallyfunction = true
        invokedDeleteItemsLocallyCount += 1
        invokedDeleteItemsLocallyParameters = (itemIds, shareId)
        invokedDeleteItemsLocallyParametersList.append((itemIds, shareId))
        if let error = deleteItemsLocallyItemIdsShareIdThrowableError {
            throw error
        }
        closureDeleteItemsLocally()
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
    // MARK: - pinItem
    public var pinItemItemThrowableError: Error?
    public var closurePinItem: () -> () = {}
    public var invokedPinItemfunction = false
    public var invokedPinItemCount = 0
    public var invokedPinItemParameters: (item: any ItemIdentifiable, Void)?
    public var invokedPinItemParametersList = [(item: any ItemIdentifiable, Void)]()
    public var stubbedPinItemResult: SymmetricallyEncryptedItem!

    public func pinItem(item: any ItemIdentifiable) async throws -> SymmetricallyEncryptedItem {
        invokedPinItemfunction = true
        invokedPinItemCount += 1
        invokedPinItemParameters = (item, ())
        invokedPinItemParametersList.append((item, ()))
        if let error = pinItemItemThrowableError {
            throw error
        }
        closurePinItem()
        return stubbedPinItemResult
    }
    // MARK: - unpinItem
    public var unpinItemItemThrowableError: Error?
    public var closureUnpinItem: () -> () = {}
    public var invokedUnpinItemfunction = false
    public var invokedUnpinItemCount = 0
    public var invokedUnpinItemParameters: (item: any ItemIdentifiable, Void)?
    public var invokedUnpinItemParametersList = [(item: any ItemIdentifiable, Void)]()
    public var stubbedUnpinItemResult: SymmetricallyEncryptedItem!

    public func unpinItem(item: any ItemIdentifiable) async throws -> SymmetricallyEncryptedItem {
        invokedUnpinItemfunction = true
        invokedUnpinItemCount += 1
        invokedUnpinItemParameters = (item, ())
        invokedUnpinItemParametersList.append((item, ()))
        if let error = unpinItemItemThrowableError {
            throw error
        }
        closureUnpinItem()
        return stubbedUnpinItemResult
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
    // MARK: - refreshDataStream
    public var closureRefreshDataStream: () -> () = {}
    public var invokedRefreshDataStreamfunction = false
    public var invokedRefreshDataStreamCount = 0

    public func refreshDataStream() async {
        invokedRefreshDataStreamfunction = true
        invokedRefreshDataStreamCount += 1
        closureRefreshDataStream()
    }
    // MARK: - totpCreationDateThreshold
    public var totpCreationDateThresholdNumberOfTotpThrowableError: Error?
    public var closureTotpCreationDateThreshold: () -> () = {}
    public var invokedTotpCreationDateThresholdfunction = false
    public var invokedTotpCreationDateThresholdCount = 0
    public var invokedTotpCreationDateThresholdParameters: (numberOfTotp: Int, Void)?
    public var invokedTotpCreationDateThresholdParametersList = [(numberOfTotp: Int, Void)]()
    public var stubbedTotpCreationDateThresholdResult: Int64?

    public func totpCreationDateThreshold(numberOfTotp: Int) async throws -> Int64? {
        invokedTotpCreationDateThresholdfunction = true
        invokedTotpCreationDateThresholdCount += 1
        invokedTotpCreationDateThresholdParameters = (numberOfTotp, ())
        invokedTotpCreationDateThresholdParametersList.append((numberOfTotp, ()))
        if let error = totpCreationDateThresholdNumberOfTotpThrowableError {
            throw error
        }
        closureTotpCreationDateThreshold()
        return stubbedTotpCreationDateThresholdResult
    }
}
