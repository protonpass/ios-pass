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
    // MARK: - getAllItemContents
    public var getAllItemContentsThrowableError2: Error?
    public var closureGetAllItemContents: () -> () = {}
    public var invokedGetAllItemContentsfunction = false
    public var invokedGetAllItemContentsCount = 0
    public var stubbedGetAllItemContentsResult: [ItemContent]!

    public func getAllItemContents() async throws -> [ItemContent] {
        invokedGetAllItemContentsfunction = true
        invokedGetAllItemContentsCount += 1
        if let error = getAllItemContentsThrowableError2 {
            throw error
        }
        closureGetAllItemContents()
        return stubbedGetAllItemContentsResult
    }
    // MARK: - getItemsState
    public var getItemsStateThrowableError3: Error?
    public var closureGetItemsStateAsync3: () -> () = {}
    public var invokedGetItemsStateAsync3 = false
    public var invokedGetItemsStateAsyncCount3 = 0
    public var invokedGetItemsStateAsyncParameters3: (state: ItemState, Void)?
    public var invokedGetItemsStateAsyncParametersList3 = [(state: ItemState, Void)]()
    public var stubbedGetItemsStateAsyncResult3: [SymmetricallyEncryptedItem]!

    public func getItems(state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsStateAsync3 = true
        invokedGetItemsStateAsyncCount3 += 1
        invokedGetItemsStateAsyncParameters3 = (state, ())
        invokedGetItemsStateAsyncParametersList3.append((state, ()))
        if let error = getItemsStateThrowableError3 {
            throw error
        }
        closureGetItemsStateAsync3()
        return stubbedGetItemsStateAsyncResult3
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
    public var getAliasItemEmailThrowableError6: Error?
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
        if let error = getAliasItemEmailThrowableError6 {
            throw error
        }
        closureGetAliasItem()
        return stubbedGetAliasItemResult
    }
    // MARK: - getItemContent
    public var getItemContentShareIdItemIdThrowableError7: Error?
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
        if let error = getItemContentShareIdItemIdThrowableError7 {
            throw error
        }
        closureGetItemContent()
        return stubbedGetItemContentResult
    }
    // MARK: - getItemRevisions
    public var getItemRevisionsShareIdItemIdLastTokenThrowableError8: Error?
    public var closureGetItemRevisions: () -> () = {}
    public var invokedGetItemRevisionsfunction = false
    public var invokedGetItemRevisionsCount = 0
    public var invokedGetItemRevisionsParameters: (shareId: String, itemId: String, lastToken: String?)?
    public var invokedGetItemRevisionsParametersList = [(shareId: String, itemId: String, lastToken: String?)]()
    public var stubbedGetItemRevisionsResult: Paginated<ItemContent>!

    public func getItemRevisions(shareId: String, itemId: String, lastToken: String?) async throws -> Paginated<ItemContent> {
        invokedGetItemRevisionsfunction = true
        invokedGetItemRevisionsCount += 1
        invokedGetItemRevisionsParameters = (shareId, itemId, lastToken)
        invokedGetItemRevisionsParametersList.append((shareId, itemId, lastToken))
        if let error = getItemRevisionsShareIdItemIdLastTokenThrowableError8 {
            throw error
        }
        closureGetItemRevisions()
        return stubbedGetItemRevisionsResult
    }
    // MARK: - refreshItems
    public var refreshItemsShareIdEventStreamThrowableError9: Error?
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
        if let error = refreshItemsShareIdEventStreamThrowableError9 {
            throw error
        }
        closureRefreshItems()
    }
    // MARK: - createItem
    public var createItemItemContentShareIdThrowableError10: Error?
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
        if let error = createItemItemContentShareIdThrowableError10 {
            throw error
        }
        closureCreateItem()
        return stubbedCreateItemResult
    }
    // MARK: - createAlias
    public var createAliasInfoItemContentShareIdThrowableError11: Error?
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
        if let error = createAliasInfoItemContentShareIdThrowableError11 {
            throw error
        }
        closureCreateAlias()
        return stubbedCreateAliasResult
    }
    // MARK: - createAliasAndOtherItem
    public var createAliasAndOtherItemInfoAliasItemContentOtherItemContentShareIdThrowableError12: Error?
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
        if let error = createAliasAndOtherItemInfoAliasItemContentOtherItemContentShareIdThrowableError12 {
            throw error
        }
        closureCreateAliasAndOtherItem()
        return stubbedCreateAliasAndOtherItemResult
    }
    // MARK: - trashItemsItems
    public var trashItemsThrowableError13: Error?
    public var closureTrashItemsItemsAsync13: () -> () = {}
    public var invokedTrashItemsItemsAsync13 = false
    public var invokedTrashItemsItemsAsyncCount13 = 0
    public var invokedTrashItemsItemsAsyncParameters13: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedTrashItemsItemsAsyncParametersList13 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedTrashItemsItemsAsync13 = true
        invokedTrashItemsItemsAsyncCount13 += 1
        invokedTrashItemsItemsAsyncParameters13 = (items, ())
        invokedTrashItemsItemsAsyncParametersList13.append((items, ()))
        if let error = trashItemsThrowableError13 {
            throw error
        }
        closureTrashItemsItemsAsync13()
    }
    // MARK: - trashItemsItems
    public var trashItemsThrowableError14: Error?
    public var closureTrashItemsItemsAsync14: () -> () = {}
    public var invokedTrashItemsItemsAsync14 = false
    public var invokedTrashItemsItemsAsyncCount14 = 0
    public var invokedTrashItemsItemsAsyncParameters14: (items: [any ItemIdentifiable], Void)?
    public var invokedTrashItemsItemsAsyncParametersList14 = [(items: [any ItemIdentifiable], Void)]()

    public func trashItems(_ items: [any ItemIdentifiable]) async throws {
        invokedTrashItemsItemsAsync14 = true
        invokedTrashItemsItemsAsyncCount14 += 1
        invokedTrashItemsItemsAsyncParameters14 = (items, ())
        invokedTrashItemsItemsAsyncParametersList14.append((items, ()))
        if let error = trashItemsThrowableError14 {
            throw error
        }
        closureTrashItemsItemsAsync14()
    }
    // MARK: - deleteAlias
    public var deleteAliasEmailThrowableError15: Error?
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
        if let error = deleteAliasEmailThrowableError15 {
            throw error
        }
        closureDeleteAlias()
    }
    // MARK: - untrashItemsItems
    public var untrashItemsThrowableError16: Error?
    public var closureUntrashItemsItemsAsync16: () -> () = {}
    public var invokedUntrashItemsItemsAsync16 = false
    public var invokedUntrashItemsItemsAsyncCount16 = 0
    public var invokedUntrashItemsItemsAsyncParameters16: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUntrashItemsItemsAsyncParametersList16 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUntrashItemsItemsAsync16 = true
        invokedUntrashItemsItemsAsyncCount16 += 1
        invokedUntrashItemsItemsAsyncParameters16 = (items, ())
        invokedUntrashItemsItemsAsyncParametersList16.append((items, ()))
        if let error = untrashItemsThrowableError16 {
            throw error
        }
        closureUntrashItemsItemsAsync16()
    }
    // MARK: - untrashItemsItems
    public var untrashItemsThrowableError17: Error?
    public var closureUntrashItemsItemsAsync17: () -> () = {}
    public var invokedUntrashItemsItemsAsync17 = false
    public var invokedUntrashItemsItemsAsyncCount17 = 0
    public var invokedUntrashItemsItemsAsyncParameters17: (items: [any ItemIdentifiable], Void)?
    public var invokedUntrashItemsItemsAsyncParametersList17 = [(items: [any ItemIdentifiable], Void)]()

    public func untrashItems(_ items: [any ItemIdentifiable]) async throws {
        invokedUntrashItemsItemsAsync17 = true
        invokedUntrashItemsItemsAsyncCount17 += 1
        invokedUntrashItemsItemsAsyncParameters17 = (items, ())
        invokedUntrashItemsItemsAsyncParametersList17.append((items, ()))
        if let error = untrashItemsThrowableError17 {
            throw error
        }
        closureUntrashItemsItemsAsync17()
    }
    // MARK: - deleteItems
    public var deleteItemsSkipTrashThrowableError18: Error?
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
        if let error = deleteItemsSkipTrashThrowableError18 {
            throw error
        }
        closureDeleteItems()
    }
    // MARK: - delete
    public var deleteItemsThrowableError19: Error?
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
        if let error = deleteItemsThrowableError19 {
            throw error
        }
        closureDelete()
    }
    // MARK: - updateItem
    public var updateItemOldItemNewItemContentShareIdThrowableError20: Error?
    public var closureUpdateItem: () -> () = {}
    public var invokedUpdateItemfunction = false
    public var invokedUpdateItemCount = 0
    public var invokedUpdateItemParameters: (oldItem: Item, newItemContent: any ProtobufableItemContentProtocol, shareId: String)?
    public var invokedUpdateItemParametersList = [(oldItem: Item, newItemContent: any ProtobufableItemContentProtocol, shareId: String)]()

    public func updateItem(oldItem: Item, newItemContent: any ProtobufableItemContentProtocol, shareId: String) async throws {
        invokedUpdateItemfunction = true
        invokedUpdateItemCount += 1
        invokedUpdateItemParameters = (oldItem, newItemContent, shareId)
        invokedUpdateItemParametersList.append((oldItem, newItemContent, shareId))
        if let error = updateItemOldItemNewItemContentShareIdThrowableError20 {
            throw error
        }
        closureUpdateItem()
    }
    // MARK: - upsertItems
    public var upsertItemsShareIdThrowableError21: Error?
    public var closureUpsertItems: () -> () = {}
    public var invokedUpsertItemsfunction = false
    public var invokedUpsertItemsCount = 0
    public var invokedUpsertItemsParameters: (items: [Item], shareId: String)?
    public var invokedUpsertItemsParametersList = [(items: [Item], shareId: String)]()

    public func upsertItems(_ items: [Item], shareId: String) async throws {
        invokedUpsertItemsfunction = true
        invokedUpsertItemsCount += 1
        invokedUpsertItemsParameters = (items, shareId)
        invokedUpsertItemsParametersList.append((items, shareId))
        if let error = upsertItemsShareIdThrowableError21 {
            throw error
        }
        closureUpsertItems()
    }
    // MARK: - update
    public var updateLastUseItemsShareIdThrowableError22: Error?
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
        if let error = updateLastUseItemsShareIdThrowableError22 {
            throw error
        }
        closureUpdate()
    }
    // MARK: - updateLastUseTime
    public var updateLastUseTimeItemDateThrowableError23: Error?
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
        if let error = updateLastUseTimeItemDateThrowableError23 {
            throw error
        }
        closureUpdateLastUseTime()
    }
    // MARK: - moveItemToShareId
    public var moveItemToShareIdThrowableError24: Error?
    public var closureMoveItemToShareIdAsync24: () -> () = {}
    public var invokedMoveItemToShareIdAsync24 = false
    public var invokedMoveItemToShareIdAsyncCount24 = 0
    public var invokedMoveItemToShareIdAsyncParameters24: (item: any ItemIdentifiable, toShareId: String)?
    public var invokedMoveItemToShareIdAsyncParametersList24 = [(item: any ItemIdentifiable, toShareId: String)]()
    public var stubbedMoveItemToShareIdAsyncResult24: SymmetricallyEncryptedItem!

    public func move(item: any ItemIdentifiable, toShareId: String) async throws -> SymmetricallyEncryptedItem {
        invokedMoveItemToShareIdAsync24 = true
        invokedMoveItemToShareIdAsyncCount24 += 1
        invokedMoveItemToShareIdAsyncParameters24 = (item, toShareId)
        invokedMoveItemToShareIdAsyncParametersList24.append((item, toShareId))
        if let error = moveItemToShareIdThrowableError24 {
            throw error
        }
        closureMoveItemToShareIdAsync24()
        return stubbedMoveItemToShareIdAsyncResult24
    }
    // MARK: - moveItemsToShareId
    public var moveItemsToShareIdThrowableError25: Error?
    public var closureMoveItemsToShareIdAsync25: () -> () = {}
    public var invokedMoveItemsToShareIdAsync25 = false
    public var invokedMoveItemsToShareIdAsyncCount25 = 0
    public var invokedMoveItemsToShareIdAsyncParameters25: (items: [any ItemIdentifiable], toShareId: String)?
    public var invokedMoveItemsToShareIdAsyncParametersList25 = [(items: [any ItemIdentifiable], toShareId: String)]()

    public func move(items: [any ItemIdentifiable], toShareId: String) async throws {
        invokedMoveItemsToShareIdAsync25 = true
        invokedMoveItemsToShareIdAsyncCount25 += 1
        invokedMoveItemsToShareIdAsyncParameters25 = (items, toShareId)
        invokedMoveItemsToShareIdAsyncParametersList25.append((items, toShareId))
        if let error = moveItemsToShareIdThrowableError25 {
            throw error
        }
        closureMoveItemsToShareIdAsync25()
    }
    // MARK: - moveCurrentShareIdToShareId
    public var moveCurrentShareIdToShareIdThrowableError26: Error?
    public var closureMoveCurrentShareIdToShareIdAsync26: () -> () = {}
    public var invokedMoveCurrentShareIdToShareIdAsync26 = false
    public var invokedMoveCurrentShareIdToShareIdAsyncCount26 = 0
    public var invokedMoveCurrentShareIdToShareIdAsyncParameters26: (currentShareId: String, toShareId: String)?
    public var invokedMoveCurrentShareIdToShareIdAsyncParametersList26 = [(currentShareId: String, toShareId: String)]()
    public var stubbedMoveCurrentShareIdToShareIdAsyncResult26: [SymmetricallyEncryptedItem]!

    public func move(currentShareId: String, toShareId: String) async throws -> [SymmetricallyEncryptedItem] {
        invokedMoveCurrentShareIdToShareIdAsync26 = true
        invokedMoveCurrentShareIdToShareIdAsyncCount26 += 1
        invokedMoveCurrentShareIdToShareIdAsyncParameters26 = (currentShareId, toShareId)
        invokedMoveCurrentShareIdToShareIdAsyncParametersList26.append((currentShareId, toShareId))
        if let error = moveCurrentShareIdToShareIdThrowableError26 {
            throw error
        }
        closureMoveCurrentShareIdToShareIdAsync26()
        return stubbedMoveCurrentShareIdToShareIdAsyncResult26
    }
    // MARK: - deleteAllItemsLocally
    public var deleteAllItemsLocallyThrowableError27: Error?
    public var closureDeleteAllItemsLocallyAsync27: () -> () = {}
    public var invokedDeleteAllItemsLocallyAsync27 = false
    public var invokedDeleteAllItemsLocallyAsyncCount27 = 0

    public func deleteAllItemsLocally() async throws {
        invokedDeleteAllItemsLocallyAsync27 = true
        invokedDeleteAllItemsLocallyAsyncCount27 += 1
        if let error = deleteAllItemsLocallyThrowableError27 {
            throw error
        }
        closureDeleteAllItemsLocallyAsync27()
    }
    // MARK: - deleteAllItemsLocallyShareId
    public var deleteAllItemsLocallyShareIdThrowableError28: Error?
    public var closureDeleteAllItemsLocallyShareIdAsync28: () -> () = {}
    public var invokedDeleteAllItemsLocallyShareIdAsync28 = false
    public var invokedDeleteAllItemsLocallyShareIdAsyncCount28 = 0
    public var invokedDeleteAllItemsLocallyShareIdAsyncParameters28: (shareId: String, Void)?
    public var invokedDeleteAllItemsLocallyShareIdAsyncParametersList28 = [(shareId: String, Void)]()

    public func deleteAllItemsLocally(shareId: String) async throws {
        invokedDeleteAllItemsLocallyShareIdAsync28 = true
        invokedDeleteAllItemsLocallyShareIdAsyncCount28 += 1
        invokedDeleteAllItemsLocallyShareIdAsyncParameters28 = (shareId, ())
        invokedDeleteAllItemsLocallyShareIdAsyncParametersList28.append((shareId, ()))
        if let error = deleteAllItemsLocallyShareIdThrowableError28 {
            throw error
        }
        closureDeleteAllItemsLocallyShareIdAsync28()
    }
    // MARK: - deleteItemsLocally
    public var deleteItemsLocallyItemIdsShareIdThrowableError29: Error?
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
        if let error = deleteItemsLocallyItemIdsShareIdThrowableError29 {
            throw error
        }
        closureDeleteItemsLocally()
    }
    // MARK: - getActiveLogInItems
    public var getActiveLogInItemsThrowableError30: Error?
    public var closureGetActiveLogInItems: () -> () = {}
    public var invokedGetActiveLogInItemsfunction = false
    public var invokedGetActiveLogInItemsCount = 0
    public var stubbedGetActiveLogInItemsResult: [SymmetricallyEncryptedItem]!

    public func getActiveLogInItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetActiveLogInItemsfunction = true
        invokedGetActiveLogInItemsCount += 1
        if let error = getActiveLogInItemsThrowableError30 {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
    // MARK: - pinItem
    public var pinItemItemThrowableError31: Error?
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
        if let error = pinItemItemThrowableError31 {
            throw error
        }
        closurePinItem()
        return stubbedPinItemResult
    }
    // MARK: - unpinItem
    public var unpinItemItemThrowableError32: Error?
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
        if let error = unpinItemItemThrowableError32 {
            throw error
        }
        closureUnpinItem()
        return stubbedUnpinItemResult
    }
    // MARK: - getAllPinnedItems
    public var getAllPinnedItemsThrowableError33: Error?
    public var closureGetAllPinnedItems: () -> () = {}
    public var invokedGetAllPinnedItemsfunction = false
    public var invokedGetAllPinnedItemsCount = 0
    public var stubbedGetAllPinnedItemsResult: [SymmetricallyEncryptedItem]!

    public func getAllPinnedItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetAllPinnedItemsfunction = true
        invokedGetAllPinnedItemsCount += 1
        if let error = getAllPinnedItemsThrowableError33 {
            throw error
        }
        closureGetAllPinnedItems()
        return stubbedGetAllPinnedItemsResult
    }
    // MARK: - totpCreationDateThreshold
    public var totpCreationDateThresholdNumberOfTotpThrowableError34: Error?
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
        if let error = totpCreationDateThresholdNumberOfTotpThrowableError34 {
            throw error
        }
        closureTotpCreationDateThreshold()
        return stubbedTotpCreationDateThresholdResult
    }
}
