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
    // MARK: - getItemContent
    public var getItemContentShareIdItemIdThrowableError6: Error?
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
        if let error = getItemContentShareIdItemIdThrowableError6 {
            throw error
        }
        closureGetItemContent()
        return stubbedGetItemContentResult
    }
    // MARK: - refreshItems
    public var refreshItemsShareIdEventStreamThrowableError7: Error?
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
        if let error = refreshItemsShareIdEventStreamThrowableError7 {
            throw error
        }
        closureRefreshItems()
    }
    // MARK: - createItem
    public var createItemItemContentShareIdThrowableError8: Error?
    public var closureCreateItem: () -> () = {}
    public var invokedCreateItemfunction = false
    public var invokedCreateItemCount = 0
    public var invokedCreateItemParameters: (itemContent: any ProtobufableItemContentProtocol, shareId: String)?
    public var invokedCreateItemParametersList = [(itemContent: any ProtobufableItemContentProtocol, shareId: String)]()
    public var stubbedCreateItemResult: SymmetricallyEncryptedItem!

    public func createItem(itemContent: any ProtobufableItemContentProtocol, shareId: String) async throws -> SymmetricallyEncryptedItem {
        invokedCreateItemfunction = true
        invokedCreateItemCount += 1
        invokedCreateItemParameters = (itemContent, shareId)
        invokedCreateItemParametersList.append((itemContent, shareId))
        if let error = createItemItemContentShareIdThrowableError8 {
            throw error
        }
        closureCreateItem()
        return stubbedCreateItemResult
    }
    // MARK: - createAlias
    public var createAliasInfoItemContentShareIdThrowableError9: Error?
    public var closureCreateAlias: () -> () = {}
    public var invokedCreateAliasfunction = false
    public var invokedCreateAliasCount = 0
    public var invokedCreateAliasParameters: (info: AliasCreationInfo, itemContent: any ProtobufableItemContentProtocol, shareId: String)?
    public var invokedCreateAliasParametersList = [(info: AliasCreationInfo, itemContent: any ProtobufableItemContentProtocol, shareId: String)]()
    public var stubbedCreateAliasResult: SymmetricallyEncryptedItem!

    public func createAlias(info: AliasCreationInfo, itemContent: any ProtobufableItemContentProtocol, shareId: String) async throws -> SymmetricallyEncryptedItem {
        invokedCreateAliasfunction = true
        invokedCreateAliasCount += 1
        invokedCreateAliasParameters = (info, itemContent, shareId)
        invokedCreateAliasParametersList.append((info, itemContent, shareId))
        if let error = createAliasInfoItemContentShareIdThrowableError9 {
            throw error
        }
        closureCreateAlias()
        return stubbedCreateAliasResult
    }
    // MARK: - createAliasAndOtherItem
    public var createAliasAndOtherItemInfoAliasItemContentOtherItemContentShareIdThrowableError10: Error?
    public var closureCreateAliasAndOtherItem: () -> () = {}
    public var invokedCreateAliasAndOtherItemfunction = false
    public var invokedCreateAliasAndOtherItemCount = 0
    public var invokedCreateAliasAndOtherItemParameters: (info: AliasCreationInfo, aliasItemContent: any ProtobufableItemContentProtocol, otherItemContent: any ProtobufableItemContentProtocol, shareId: String)?
    public var invokedCreateAliasAndOtherItemParametersList = [(info: AliasCreationInfo, aliasItemContent: any ProtobufableItemContentProtocol, otherItemContent: any ProtobufableItemContentProtocol, shareId: String)]()
    public var stubbedCreateAliasAndOtherItemResult: (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem)!

    public func createAliasAndOtherItem(info: AliasCreationInfo, aliasItemContent: any ProtobufableItemContentProtocol, otherItemContent: any ProtobufableItemContentProtocol, shareId: String) async throws -> (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem) {
        invokedCreateAliasAndOtherItemfunction = true
        invokedCreateAliasAndOtherItemCount += 1
        invokedCreateAliasAndOtherItemParameters = (info, aliasItemContent, otherItemContent, shareId)
        invokedCreateAliasAndOtherItemParametersList.append((info, aliasItemContent, otherItemContent, shareId))
        if let error = createAliasAndOtherItemInfoAliasItemContentOtherItemContentShareIdThrowableError10 {
            throw error
        }
        closureCreateAliasAndOtherItem()
        return stubbedCreateAliasAndOtherItemResult
    }
    // MARK: - trashItemsItems
    public var trashItemsThrowableError11: Error?
    public var closureTrashItemsItemsAsync11: () -> () = {}
    public var invokedTrashItemsItemsAsync11 = false
    public var invokedTrashItemsItemsAsyncCount11 = 0
    public var invokedTrashItemsItemsAsyncParameters11: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedTrashItemsItemsAsyncParametersList11 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedTrashItemsItemsAsync11 = true
        invokedTrashItemsItemsAsyncCount11 += 1
        invokedTrashItemsItemsAsyncParameters11 = (items, ())
        invokedTrashItemsItemsAsyncParametersList11.append((items, ()))
        if let error = trashItemsThrowableError11 {
            throw error
        }
        closureTrashItemsItemsAsync11()
    }
    // MARK: - trashItemsItems
    public var trashItemsThrowableError12: Error?
    public var closureTrashItemsItemsAsync12: () -> () = {}
    public var invokedTrashItemsItemsAsync12 = false
    public var invokedTrashItemsItemsAsyncCount12 = 0
    public var invokedTrashItemsItemsAsyncParameters12: (items: [any ItemIdentifiable], Void)?
    public var invokedTrashItemsItemsAsyncParametersList12 = [(items: [any ItemIdentifiable], Void)]()

    public func trashItems(_ items: [any ItemIdentifiable]) async throws {
        invokedTrashItemsItemsAsync12 = true
        invokedTrashItemsItemsAsyncCount12 += 1
        invokedTrashItemsItemsAsyncParameters12 = (items, ())
        invokedTrashItemsItemsAsyncParametersList12.append((items, ()))
        if let error = trashItemsThrowableError12 {
            throw error
        }
        closureTrashItemsItemsAsync12()
    }
    // MARK: - deleteAlias
    public var deleteAliasEmailThrowableError13: Error?
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
        if let error = deleteAliasEmailThrowableError13 {
            throw error
        }
        closureDeleteAlias()
    }
    // MARK: - untrashItemsItems
    public var untrashItemsThrowableError14: Error?
    public var closureUntrashItemsItemsAsync14: () -> () = {}
    public var invokedUntrashItemsItemsAsync14 = false
    public var invokedUntrashItemsItemsAsyncCount14 = 0
    public var invokedUntrashItemsItemsAsyncParameters14: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUntrashItemsItemsAsyncParametersList14 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUntrashItemsItemsAsync14 = true
        invokedUntrashItemsItemsAsyncCount14 += 1
        invokedUntrashItemsItemsAsyncParameters14 = (items, ())
        invokedUntrashItemsItemsAsyncParametersList14.append((items, ()))
        if let error = untrashItemsThrowableError14 {
            throw error
        }
        closureUntrashItemsItemsAsync14()
    }
    // MARK: - untrashItemsItems
    public var untrashItemsThrowableError15: Error?
    public var closureUntrashItemsItemsAsync15: () -> () = {}
    public var invokedUntrashItemsItemsAsync15 = false
    public var invokedUntrashItemsItemsAsyncCount15 = 0
    public var invokedUntrashItemsItemsAsyncParameters15: (items: [any ItemIdentifiable], Void)?
    public var invokedUntrashItemsItemsAsyncParametersList15 = [(items: [any ItemIdentifiable], Void)]()

    public func untrashItems(_ items: [any ItemIdentifiable]) async throws {
        invokedUntrashItemsItemsAsync15 = true
        invokedUntrashItemsItemsAsyncCount15 += 1
        invokedUntrashItemsItemsAsyncParameters15 = (items, ())
        invokedUntrashItemsItemsAsyncParametersList15.append((items, ()))
        if let error = untrashItemsThrowableError15 {
            throw error
        }
        closureUntrashItemsItemsAsync15()
    }
    // MARK: - deleteItems
    public var deleteItemsSkipTrashThrowableError16: Error?
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
        if let error = deleteItemsSkipTrashThrowableError16 {
            throw error
        }
        closureDeleteItems()
    }
    // MARK: - delete
    public var deleteItemsThrowableError17: Error?
    public var closureDelete: () -> () = {}
    public var invokedDeletefunction = false
    public var invokedDeleteCount = 0
    public var invokedDeleteParameters: (items: [any ItemIdentifiable], Void)?
    public var invokedDeleteParametersList = [(items: [any ItemIdentifiable], Void)]()

    public func delete(items: [any ItemIdentifiable]) async throws {
        invokedDeletefunction = true
        invokedDeleteCount += 1
        invokedDeleteParameters = (items, ())
        invokedDeleteParametersList.append((items, ()))
        if let error = deleteItemsThrowableError17 {
            throw error
        }
        closureDelete()
    }
    // MARK: - updateItem
    public var updateItemOldItemNewItemContentShareIdThrowableError18: Error?
    public var closureUpdateItem: () -> () = {}
    public var invokedUpdateItemfunction = false
    public var invokedUpdateItemCount = 0
    public var invokedUpdateItemParameters: (oldItem: ItemRevision, newItemContent: any ProtobufableItemContentProtocol, shareId: String)?
    public var invokedUpdateItemParametersList = [(oldItem: ItemRevision, newItemContent: any ProtobufableItemContentProtocol, shareId: String)]()

    public func updateItem(oldItem: ItemRevision, newItemContent: any ProtobufableItemContentProtocol, shareId: String) async throws {
        invokedUpdateItemfunction = true
        invokedUpdateItemCount += 1
        invokedUpdateItemParameters = (oldItem, newItemContent, shareId)
        invokedUpdateItemParametersList.append((oldItem, newItemContent, shareId))
        if let error = updateItemOldItemNewItemContentShareIdThrowableError18 {
            throw error
        }
        closureUpdateItem()
    }
    // MARK: - upsertItems
    public var upsertItemsShareIdThrowableError19: Error?
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
        if let error = upsertItemsShareIdThrowableError19 {
            throw error
        }
        closureUpsertItems()
    }
    // MARK: - update
    public var updateLastUseItemsShareIdThrowableError20: Error?
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
        if let error = updateLastUseItemsShareIdThrowableError20 {
            throw error
        }
        closureUpdate()
    }
    // MARK: - updateLastUseTime
    public var updateLastUseTimeItemDateThrowableError21: Error?
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
        if let error = updateLastUseTimeItemDateThrowableError21 {
            throw error
        }
        closureUpdateLastUseTime()
    }
    // MARK: - moveItemToShareId
    public var moveItemToShareIdThrowableError22: Error?
    public var closureMoveItemToShareIdAsync22: () -> () = {}
    public var invokedMoveItemToShareIdAsync22 = false
    public var invokedMoveItemToShareIdAsyncCount22 = 0
    public var invokedMoveItemToShareIdAsyncParameters22: (item: any ItemIdentifiable, toShareId: String)?
    public var invokedMoveItemToShareIdAsyncParametersList22 = [(item: any ItemIdentifiable, toShareId: String)]()
    public var stubbedMoveItemToShareIdAsyncResult22: SymmetricallyEncryptedItem!

    public func move(item: any ItemIdentifiable, toShareId: String) async throws -> SymmetricallyEncryptedItem {
        invokedMoveItemToShareIdAsync22 = true
        invokedMoveItemToShareIdAsyncCount22 += 1
        invokedMoveItemToShareIdAsyncParameters22 = (item, toShareId)
        invokedMoveItemToShareIdAsyncParametersList22.append((item, toShareId))
        if let error = moveItemToShareIdThrowableError22 {
            throw error
        }
        closureMoveItemToShareIdAsync22()
        return stubbedMoveItemToShareIdAsyncResult22
    }
    // MARK: - moveItemsToShareId
    public var moveItemsToShareIdThrowableError23: Error?
    public var closureMoveItemsToShareIdAsync23: () -> () = {}
    public var invokedMoveItemsToShareIdAsync23 = false
    public var invokedMoveItemsToShareIdAsyncCount23 = 0
    public var invokedMoveItemsToShareIdAsyncParameters23: (items: [any ItemIdentifiable], toShareId: String)?
    public var invokedMoveItemsToShareIdAsyncParametersList23 = [(items: [any ItemIdentifiable], toShareId: String)]()

    public func move(items: [any ItemIdentifiable], toShareId: String) async throws {
        invokedMoveItemsToShareIdAsync23 = true
        invokedMoveItemsToShareIdAsyncCount23 += 1
        invokedMoveItemsToShareIdAsyncParameters23 = (items, toShareId)
        invokedMoveItemsToShareIdAsyncParametersList23.append((items, toShareId))
        if let error = moveItemsToShareIdThrowableError23 {
            throw error
        }
        closureMoveItemsToShareIdAsync23()
    }
    // MARK: - moveCurrentShareIdToShareId
    public var moveCurrentShareIdToShareIdThrowableError24: Error?
    public var closureMoveCurrentShareIdToShareIdAsync24: () -> () = {}
    public var invokedMoveCurrentShareIdToShareIdAsync24 = false
    public var invokedMoveCurrentShareIdToShareIdAsyncCount24 = 0
    public var invokedMoveCurrentShareIdToShareIdAsyncParameters24: (currentShareId: String, toShareId: String)?
    public var invokedMoveCurrentShareIdToShareIdAsyncParametersList24 = [(currentShareId: String, toShareId: String)]()
    public var stubbedMoveCurrentShareIdToShareIdAsyncResult24: [SymmetricallyEncryptedItem]!

    public func move(currentShareId: String, toShareId: String) async throws -> [SymmetricallyEncryptedItem] {
        invokedMoveCurrentShareIdToShareIdAsync24 = true
        invokedMoveCurrentShareIdToShareIdAsyncCount24 += 1
        invokedMoveCurrentShareIdToShareIdAsyncParameters24 = (currentShareId, toShareId)
        invokedMoveCurrentShareIdToShareIdAsyncParametersList24.append((currentShareId, toShareId))
        if let error = moveCurrentShareIdToShareIdThrowableError24 {
            throw error
        }
        closureMoveCurrentShareIdToShareIdAsync24()
        return stubbedMoveCurrentShareIdToShareIdAsyncResult24
    }
    // MARK: - deleteAllItemsLocally
    public var deleteAllItemsLocallyThrowableError25: Error?
    public var closureDeleteAllItemsLocallyAsync25: () -> () = {}
    public var invokedDeleteAllItemsLocallyAsync25 = false
    public var invokedDeleteAllItemsLocallyAsyncCount25 = 0

    public func deleteAllItemsLocally() async throws {
        invokedDeleteAllItemsLocallyAsync25 = true
        invokedDeleteAllItemsLocallyAsyncCount25 += 1
        if let error = deleteAllItemsLocallyThrowableError25 {
            throw error
        }
        closureDeleteAllItemsLocallyAsync25()
    }
    // MARK: - deleteAllItemsLocallyShareId
    public var deleteAllItemsLocallyShareIdThrowableError26: Error?
    public var closureDeleteAllItemsLocallyShareIdAsync26: () -> () = {}
    public var invokedDeleteAllItemsLocallyShareIdAsync26 = false
    public var invokedDeleteAllItemsLocallyShareIdAsyncCount26 = 0
    public var invokedDeleteAllItemsLocallyShareIdAsyncParameters26: (shareId: String, Void)?
    public var invokedDeleteAllItemsLocallyShareIdAsyncParametersList26 = [(shareId: String, Void)]()

    public func deleteAllItemsLocally(shareId: String) async throws {
        invokedDeleteAllItemsLocallyShareIdAsync26 = true
        invokedDeleteAllItemsLocallyShareIdAsyncCount26 += 1
        invokedDeleteAllItemsLocallyShareIdAsyncParameters26 = (shareId, ())
        invokedDeleteAllItemsLocallyShareIdAsyncParametersList26.append((shareId, ()))
        if let error = deleteAllItemsLocallyShareIdThrowableError26 {
            throw error
        }
        closureDeleteAllItemsLocallyShareIdAsync26()
    }
    // MARK: - deleteItemsLocally
    public var deleteItemsLocallyItemIdsShareIdThrowableError27: Error?
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
        if let error = deleteItemsLocallyItemIdsShareIdThrowableError27 {
            throw error
        }
        closureDeleteItemsLocally()
    }
    // MARK: - getActiveLogInItems
    public var getActiveLogInItemsThrowableError28: Error?
    public var closureGetActiveLogInItems: () -> () = {}
    public var invokedGetActiveLogInItemsfunction = false
    public var invokedGetActiveLogInItemsCount = 0
    public var stubbedGetActiveLogInItemsResult: [SymmetricallyEncryptedItem]!

    public func getActiveLogInItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetActiveLogInItemsfunction = true
        invokedGetActiveLogInItemsCount += 1
        if let error = getActiveLogInItemsThrowableError28 {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
    // MARK: - pinItem
    public var pinItemItemThrowableError29: Error?
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
        if let error = pinItemItemThrowableError29 {
            throw error
        }
        closurePinItem()
        return stubbedPinItemResult
    }
    // MARK: - unpinItem
    public var unpinItemItemThrowableError30: Error?
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
        if let error = unpinItemItemThrowableError30 {
            throw error
        }
        closureUnpinItem()
        return stubbedUnpinItemResult
    }
    // MARK: - getAllPinnedItems
    public var getAllPinnedItemsThrowableError31: Error?
    public var closureGetAllPinnedItems: () -> () = {}
    public var invokedGetAllPinnedItemsfunction = false
    public var invokedGetAllPinnedItemsCount = 0
    public var stubbedGetAllPinnedItemsResult: [SymmetricallyEncryptedItem]!

    public func getAllPinnedItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetAllPinnedItemsfunction = true
        invokedGetAllPinnedItemsCount += 1
        if let error = getAllPinnedItemsThrowableError31 {
            throw error
        }
        closureGetAllPinnedItems()
        return stubbedGetAllPinnedItemsResult
    }
    // MARK: - totpCreationDateThreshold
    public var totpCreationDateThresholdNumberOfTotpThrowableError32: Error?
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
        if let error = totpCreationDateThresholdNumberOfTotpThrowableError32 {
            throw error
        }
        closureTotpCreationDateThreshold()
        return stubbedTotpCreationDateThresholdResult
    }
}
