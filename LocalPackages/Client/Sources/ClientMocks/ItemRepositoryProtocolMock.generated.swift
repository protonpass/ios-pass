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
import Combine
import Core
import CoreData
import CryptoKit
import Entities
import ProtonCoreLogin

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
    // MARK: - itemsWereUpdated
    public var invokedItemsWereUpdatedSetter = false
    public var invokedItemsWereUpdatedSetterCount = 0
    public var invokedItemsWereUpdated: CurrentValueSubject<Void, Never>?
    public var invokedItemsWereUpdatedList = [CurrentValueSubject<Void, Never>?]()
    public var invokedItemsWereUpdatedGetter = false
    public var invokedItemsWereUpdatedGetterCount = 0
    public var stubbedItemsWereUpdated: CurrentValueSubject<Void, Never>!
    public var itemsWereUpdated: CurrentValueSubject<Void, Never> {
        set {
            invokedItemsWereUpdatedSetter = true
            invokedItemsWereUpdatedSetterCount += 1
            invokedItemsWereUpdated = newValue
            invokedItemsWereUpdatedList.append(newValue)
        } get {
            invokedItemsWereUpdatedGetter = true
            invokedItemsWereUpdatedGetterCount += 1
            return stubbedItemsWereUpdated
        }
    }
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
    // MARK: - getAllItemContents
    public var getAllItemContentsUserIdThrowableError2: Error?
    public var closureGetAllItemContents: () -> () = {}
    public var invokedGetAllItemContentsfunction = false
    public var invokedGetAllItemContentsCount = 0
    public var invokedGetAllItemContentsParameters: (userId: String, Void)?
    public var invokedGetAllItemContentsParametersList = [(userId: String, Void)]()
    public var stubbedGetAllItemContentsResult: [ItemContent]!

    public func getAllItemContents(userId: String) async throws -> [ItemContent] {
        invokedGetAllItemContentsfunction = true
        invokedGetAllItemContentsCount += 1
        invokedGetAllItemContentsParameters = (userId, ())
        invokedGetAllItemContentsParametersList.append((userId, ()))
        if let error = getAllItemContentsUserIdThrowableError2 {
            throw error
        }
        closureGetAllItemContents()
        return stubbedGetAllItemContentsResult
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
    // MARK: - changeAliasStatus
    public var changeAliasStatusUserIdItemsEnabledThrowableError7: Error?
    public var closureChangeAliasStatus: () -> () = {}
    public var invokedChangeAliasStatusfunction = false
    public var invokedChangeAliasStatusCount = 0
    public var invokedChangeAliasStatusParameters: (userId: String, items: [any ItemIdentifiable], enabled: Bool)?
    public var invokedChangeAliasStatusParametersList = [(userId: String, items: [any ItemIdentifiable], enabled: Bool)]()

    public func changeAliasStatus(userId: String, items: [any ItemIdentifiable], enabled: Bool) async throws {
        invokedChangeAliasStatusfunction = true
        invokedChangeAliasStatusCount += 1
        invokedChangeAliasStatusParameters = (userId, items, enabled)
        invokedChangeAliasStatusParametersList.append((userId, items, enabled))
        if let error = changeAliasStatusUserIdItemsEnabledThrowableError7 {
            throw error
        }
        closureChangeAliasStatus()
    }
    // MARK: - getItemContent
    public var getItemContentShareIdItemIdThrowableError8: Error?
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
        if let error = getItemContentShareIdItemIdThrowableError8 {
            throw error
        }
        closureGetItemContent()
        return stubbedGetItemContentResult
    }
    // MARK: - getItemRevisions
    public var getItemRevisionsUserIdShareIdItemIdLastTokenThrowableError9: Error?
    public var closureGetItemRevisions: () -> () = {}
    public var invokedGetItemRevisionsfunction = false
    public var invokedGetItemRevisionsCount = 0
    public var invokedGetItemRevisionsParameters: (userId: String, shareId: String, itemId: String, lastToken: String?)?
    public var invokedGetItemRevisionsParametersList = [(userId: String, shareId: String, itemId: String, lastToken: String?)]()
    public var stubbedGetItemRevisionsResult: Paginated<ItemContent>!

    public func getItemRevisions(userId: String, shareId: String, itemId: String, lastToken: String?) async throws -> Paginated<ItemContent> {
        invokedGetItemRevisionsfunction = true
        invokedGetItemRevisionsCount += 1
        invokedGetItemRevisionsParameters = (userId, shareId, itemId, lastToken)
        invokedGetItemRevisionsParametersList.append((userId, shareId, itemId, lastToken))
        if let error = getItemRevisionsUserIdShareIdItemIdLastTokenThrowableError9 {
            throw error
        }
        closureGetItemRevisions()
        return stubbedGetItemRevisionsResult
    }
    // MARK: - refreshItems
    public var refreshItemsUserIdShareIdEventStreamThrowableError10: Error?
    public var closureRefreshItems: () -> () = {}
    public var invokedRefreshItemsfunction = false
    public var invokedRefreshItemsCount = 0
    public var invokedRefreshItemsParameters: (userId: String, shareId: String, eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?)?
    public var invokedRefreshItemsParametersList = [(userId: String, shareId: String, eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?)]()

    public func refreshItems(userId: String, shareId: String, eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?) async throws {
        invokedRefreshItemsfunction = true
        invokedRefreshItemsCount += 1
        invokedRefreshItemsParameters = (userId, shareId, eventStream)
        invokedRefreshItemsParametersList.append((userId, shareId, eventStream))
        if let error = refreshItemsUserIdShareIdEventStreamThrowableError10 {
            throw error
        }
        closureRefreshItems()
    }
    // MARK: - refreshItem
    public var refreshItemUserIdShareIdItemIdEventTokenThrowableError11: Error?
    public var closureRefreshItem: () -> () = {}
    public var invokedRefreshItemfunction = false
    public var invokedRefreshItemCount = 0
    public var invokedRefreshItemParameters: (userId: String, shareId: String, itemId: String, eventToken: String)?
    public var invokedRefreshItemParametersList = [(userId: String, shareId: String, itemId: String, eventToken: String)]()

    public func refreshItem(userId: String, shareId: String, itemId: String, eventToken: String) async throws {
        invokedRefreshItemfunction = true
        invokedRefreshItemCount += 1
        invokedRefreshItemParameters = (userId, shareId, itemId, eventToken)
        invokedRefreshItemParametersList.append((userId, shareId, itemId, eventToken))
        if let error = refreshItemUserIdShareIdItemIdEventTokenThrowableError11 {
            throw error
        }
        closureRefreshItem()
    }
    // MARK: - createItem
    public var createItemUserIdItemContentShareIdThrowableError12: Error?
    public var closureCreateItem: () -> () = {}
    public var invokedCreateItemfunction = false
    public var invokedCreateItemCount = 0
    public var invokedCreateItemParameters: (userId: String, itemContent: any ProtobufableItemContentProtocol, shareId: String)?
    public var invokedCreateItemParametersList = [(userId: String, itemContent: any ProtobufableItemContentProtocol, shareId: String)]()
    public var stubbedCreateItemResult: SymmetricallyEncryptedItem!

    public func createItem(userId: String, itemContent: any ProtobufableItemContentProtocol, shareId: String) async throws -> SymmetricallyEncryptedItem {
        invokedCreateItemfunction = true
        invokedCreateItemCount += 1
        invokedCreateItemParameters = (userId, itemContent, shareId)
        invokedCreateItemParametersList.append((userId, itemContent, shareId))
        if let error = createItemUserIdItemContentShareIdThrowableError12 {
            throw error
        }
        closureCreateItem()
        return stubbedCreateItemResult
    }
    // MARK: - createAlias
    public var createAliasUserIdInfoItemContentShareIdThrowableError13: Error?
    public var closureCreateAlias: () -> () = {}
    public var invokedCreateAliasfunction = false
    public var invokedCreateAliasCount = 0
    public var invokedCreateAliasParameters: (userId: String, info: AliasCreationInfo, itemContent: any ProtobufableItemContentProtocol, shareId: String)?
    public var invokedCreateAliasParametersList = [(userId: String, info: AliasCreationInfo, itemContent: any ProtobufableItemContentProtocol, shareId: String)]()
    public var stubbedCreateAliasResult: SymmetricallyEncryptedItem!

    public func createAlias(userId: String, info: AliasCreationInfo, itemContent: any ProtobufableItemContentProtocol, shareId: String) async throws -> SymmetricallyEncryptedItem {
        invokedCreateAliasfunction = true
        invokedCreateAliasCount += 1
        invokedCreateAliasParameters = (userId, info, itemContent, shareId)
        invokedCreateAliasParametersList.append((userId, info, itemContent, shareId))
        if let error = createAliasUserIdInfoItemContentShareIdThrowableError13 {
            throw error
        }
        closureCreateAlias()
        return stubbedCreateAliasResult
    }
    // MARK: - createPendingAliasesItem
    public var createPendingAliasesItemUserIdShareIdItemsContentThrowableError14: Error?
    public var closureCreatePendingAliasesItem: () -> () = {}
    public var invokedCreatePendingAliasesItemfunction = false
    public var invokedCreatePendingAliasesItemCount = 0
    public var invokedCreatePendingAliasesItemParameters: (userId: String, shareId: String, itemsContent: [String: any ProtobufableItemContentProtocol])?
    public var invokedCreatePendingAliasesItemParametersList = [(userId: String, shareId: String, itemsContent: [String: any ProtobufableItemContentProtocol])]()
    public var stubbedCreatePendingAliasesItemResult: [SymmetricallyEncryptedItem]!

    public func createPendingAliasesItem(userId: String, shareId: String, itemsContent: [String: any ProtobufableItemContentProtocol]) async throws -> [SymmetricallyEncryptedItem] {
        invokedCreatePendingAliasesItemfunction = true
        invokedCreatePendingAliasesItemCount += 1
        invokedCreatePendingAliasesItemParameters = (userId, shareId, itemsContent)
        invokedCreatePendingAliasesItemParametersList.append((userId, shareId, itemsContent))
        if let error = createPendingAliasesItemUserIdShareIdItemsContentThrowableError14 {
            throw error
        }
        closureCreatePendingAliasesItem()
        return stubbedCreatePendingAliasesItemResult
    }
    // MARK: - createAliasAndOtherItem
    public var createAliasAndOtherItemUserIdInfoAliasItemContentOtherItemContentShareIdThrowableError15: Error?
    public var closureCreateAliasAndOtherItem: () -> () = {}
    public var invokedCreateAliasAndOtherItemfunction = false
    public var invokedCreateAliasAndOtherItemCount = 0
    public var invokedCreateAliasAndOtherItemParameters: (userId: String, info: AliasCreationInfo, aliasItemContent: any ProtobufableItemContentProtocol, otherItemContent: any ProtobufableItemContentProtocol, shareId: String)?
    public var invokedCreateAliasAndOtherItemParametersList = [(userId: String, info: AliasCreationInfo, aliasItemContent: any ProtobufableItemContentProtocol, otherItemContent: any ProtobufableItemContentProtocol, shareId: String)]()
    public var stubbedCreateAliasAndOtherItemResult: (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem)!

    public func createAliasAndOtherItem(userId: String, info: AliasCreationInfo, aliasItemContent: any ProtobufableItemContentProtocol, otherItemContent: any ProtobufableItemContentProtocol, shareId: String) async throws -> (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem) {
        invokedCreateAliasAndOtherItemfunction = true
        invokedCreateAliasAndOtherItemCount += 1
        invokedCreateAliasAndOtherItemParameters = (userId, info, aliasItemContent, otherItemContent, shareId)
        invokedCreateAliasAndOtherItemParametersList.append((userId, info, aliasItemContent, otherItemContent, shareId))
        if let error = createAliasAndOtherItemUserIdInfoAliasItemContentOtherItemContentShareIdThrowableError15 {
            throw error
        }
        closureCreateAliasAndOtherItem()
        return stubbedCreateAliasAndOtherItemResult
    }
    // MARK: - trashItemsItems
    public var trashItemsThrowableError16: Error?
    public var closureTrashItemsItemsAsync16: () -> () = {}
    public var invokedTrashItemsItemsAsync16 = false
    public var invokedTrashItemsItemsAsyncCount16 = 0
    public var invokedTrashItemsItemsAsyncParameters16: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedTrashItemsItemsAsyncParametersList16 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedTrashItemsItemsAsync16 = true
        invokedTrashItemsItemsAsyncCount16 += 1
        invokedTrashItemsItemsAsyncParameters16 = (items, ())
        invokedTrashItemsItemsAsyncParametersList16.append((items, ()))
        if let error = trashItemsThrowableError16 {
            throw error
        }
        closureTrashItemsItemsAsync16()
    }
    // MARK: - trashItemsItems
    public var trashItemsThrowableError17: Error?
    public var closureTrashItemsItemsAsync17: () -> () = {}
    public var invokedTrashItemsItemsAsync17 = false
    public var invokedTrashItemsItemsAsyncCount17 = 0
    public var invokedTrashItemsItemsAsyncParameters17: (items: [any ItemIdentifiable], Void)?
    public var invokedTrashItemsItemsAsyncParametersList17 = [(items: [any ItemIdentifiable], Void)]()

    public func trashItems(_ items: [any ItemIdentifiable]) async throws {
        invokedTrashItemsItemsAsync17 = true
        invokedTrashItemsItemsAsyncCount17 += 1
        invokedTrashItemsItemsAsyncParameters17 = (items, ())
        invokedTrashItemsItemsAsyncParametersList17.append((items, ()))
        if let error = trashItemsThrowableError17 {
            throw error
        }
        closureTrashItemsItemsAsync17()
    }
    // MARK: - untrashItemsItems
    public var untrashItemsThrowableError18: Error?
    public var closureUntrashItemsItemsAsync18: () -> () = {}
    public var invokedUntrashItemsItemsAsync18 = false
    public var invokedUntrashItemsItemsAsyncCount18 = 0
    public var invokedUntrashItemsItemsAsyncParameters18: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUntrashItemsItemsAsyncParametersList18 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUntrashItemsItemsAsync18 = true
        invokedUntrashItemsItemsAsyncCount18 += 1
        invokedUntrashItemsItemsAsyncParameters18 = (items, ())
        invokedUntrashItemsItemsAsyncParametersList18.append((items, ()))
        if let error = untrashItemsThrowableError18 {
            throw error
        }
        closureUntrashItemsItemsAsync18()
    }
    // MARK: - untrashItemsItems
    public var untrashItemsThrowableError19: Error?
    public var closureUntrashItemsItemsAsync19: () -> () = {}
    public var invokedUntrashItemsItemsAsync19 = false
    public var invokedUntrashItemsItemsAsyncCount19 = 0
    public var invokedUntrashItemsItemsAsyncParameters19: (items: [any ItemIdentifiable], Void)?
    public var invokedUntrashItemsItemsAsyncParametersList19 = [(items: [any ItemIdentifiable], Void)]()

    public func untrashItems(_ items: [any ItemIdentifiable]) async throws {
        invokedUntrashItemsItemsAsync19 = true
        invokedUntrashItemsItemsAsyncCount19 += 1
        invokedUntrashItemsItemsAsyncParameters19 = (items, ())
        invokedUntrashItemsItemsAsyncParametersList19.append((items, ()))
        if let error = untrashItemsThrowableError19 {
            throw error
        }
        closureUntrashItemsItemsAsync19()
    }
    // MARK: - deleteItems
    public var deleteItemsUserIdSkipTrashThrowableError20: Error?
    public var closureDeleteItems: () -> () = {}
    public var invokedDeleteItemsfunction = false
    public var invokedDeleteItemsCount = 0
    public var invokedDeleteItemsParameters: (userId: String, items: [SymmetricallyEncryptedItem], skipTrash: Bool)?
    public var invokedDeleteItemsParametersList = [(userId: String, items: [SymmetricallyEncryptedItem], skipTrash: Bool)]()

    public func deleteItems(userId: String, _ items: [SymmetricallyEncryptedItem], skipTrash: Bool) async throws {
        invokedDeleteItemsfunction = true
        invokedDeleteItemsCount += 1
        invokedDeleteItemsParameters = (userId, items, skipTrash)
        invokedDeleteItemsParametersList.append((userId, items, skipTrash))
        if let error = deleteItemsUserIdSkipTrashThrowableError20 {
            throw error
        }
        closureDeleteItems()
    }
    // MARK: - delete
    public var deleteUserIdItemsThrowableError21: Error?
    public var closureDelete: () -> () = {}
    public var invokedDeletefunction = false
    public var invokedDeleteCount = 0
    public var invokedDeleteParameters: (userId: String, items: [any ItemIdentifiable])?
    public var invokedDeleteParametersList = [(userId: String, items: [any ItemIdentifiable])]()

    public func delete(userId: String, items: [any ItemIdentifiable]) async throws {
        invokedDeletefunction = true
        invokedDeleteCount += 1
        invokedDeleteParameters = (userId, items)
        invokedDeleteParametersList.append((userId, items))
        if let error = deleteUserIdItemsThrowableError21 {
            throw error
        }
        closureDelete()
    }
    // MARK: - updateItem
    public var updateItemUserIdOldItemNewItemContentShareIdThrowableError22: Error?
    public var closureUpdateItem: () -> () = {}
    public var invokedUpdateItemfunction = false
    public var invokedUpdateItemCount = 0
    public var invokedUpdateItemParameters: (userId: String, oldItem: Item, newItemContent: any ProtobufableItemContentProtocol, shareId: String)?
    public var invokedUpdateItemParametersList = [(userId: String, oldItem: Item, newItemContent: any ProtobufableItemContentProtocol, shareId: String)]()
    public var stubbedUpdateItemResult: SymmetricallyEncryptedItem!

    public func updateItem(userId: String, oldItem: Item, newItemContent: any ProtobufableItemContentProtocol, shareId: String) async throws -> SymmetricallyEncryptedItem {
        invokedUpdateItemfunction = true
        invokedUpdateItemCount += 1
        invokedUpdateItemParameters = (userId, oldItem, newItemContent, shareId)
        invokedUpdateItemParametersList.append((userId, oldItem, newItemContent, shareId))
        if let error = updateItemUserIdOldItemNewItemContentShareIdThrowableError22 {
            throw error
        }
        closureUpdateItem()
        return stubbedUpdateItemResult
    }
    // MARK: - upsertItems
    public var upsertItemsUserIdItemsShareIdThrowableError23: Error?
    public var closureUpsertItems: () -> () = {}
    public var invokedUpsertItemsfunction = false
    public var invokedUpsertItemsCount = 0
    public var invokedUpsertItemsParameters: (userId: String, items: [Item], shareId: String)?
    public var invokedUpsertItemsParametersList = [(userId: String, items: [Item], shareId: String)]()

    public func upsertItems(userId: String, items: [Item], shareId: String) async throws {
        invokedUpsertItemsfunction = true
        invokedUpsertItemsCount += 1
        invokedUpsertItemsParameters = (userId, items, shareId)
        invokedUpsertItemsParametersList.append((userId, items, shareId))
        if let error = upsertItemsUserIdItemsShareIdThrowableError23 {
            throw error
        }
        closureUpsertItems()
    }
    // MARK: - update
    public var updateLastUseItemsShareIdThrowableError24: Error?
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
        if let error = updateLastUseItemsShareIdThrowableError24 {
            throw error
        }
        closureUpdate()
    }
    // MARK: - updateLastUseTime
    public var updateLastUseTimeUserIdItemDateThrowableError25: Error?
    public var closureUpdateLastUseTime: () -> () = {}
    public var invokedUpdateLastUseTimefunction = false
    public var invokedUpdateLastUseTimeCount = 0
    public var invokedUpdateLastUseTimeParameters: (userId: String, item: any ItemIdentifiable, date: Date)?
    public var invokedUpdateLastUseTimeParametersList = [(userId: String, item: any ItemIdentifiable, date: Date)]()

    public func updateLastUseTime(userId: String, item: any ItemIdentifiable, date: Date) async throws {
        invokedUpdateLastUseTimefunction = true
        invokedUpdateLastUseTimeCount += 1
        invokedUpdateLastUseTimeParameters = (userId, item, date)
        invokedUpdateLastUseTimeParametersList.append((userId, item, date))
        if let error = updateLastUseTimeUserIdItemDateThrowableError25 {
            throw error
        }
        closureUpdateLastUseTime()
    }
    // MARK: - updateCachedAliasInfo
    public var updateCachedAliasInfoUserIdItemsAliasesThrowableError26: Error?
    public var closureUpdateCachedAliasInfo: () -> () = {}
    public var invokedUpdateCachedAliasInfofunction = false
    public var invokedUpdateCachedAliasInfoCount = 0
    public var invokedUpdateCachedAliasInfoParameters: (userId: String, items: [SymmetricallyEncryptedItem], aliases: [Alias])?
    public var invokedUpdateCachedAliasInfoParametersList = [(userId: String, items: [SymmetricallyEncryptedItem], aliases: [Alias])]()

    public func updateCachedAliasInfo(userId: String, items: [SymmetricallyEncryptedItem], aliases: [Alias]) async throws {
        invokedUpdateCachedAliasInfofunction = true
        invokedUpdateCachedAliasInfoCount += 1
        invokedUpdateCachedAliasInfoParameters = (userId, items, aliases)
        invokedUpdateCachedAliasInfoParametersList.append((userId, items, aliases))
        if let error = updateCachedAliasInfoUserIdItemsAliasesThrowableError26 {
            throw error
        }
        closureUpdateCachedAliasInfo()
    }
    // MARK: - moveItemsToShareId
    public var moveItemsToShareIdThrowableError27: Error?
    public var closureMoveItemsToShareIdAsync27: () -> () = {}
    public var invokedMoveItemsToShareIdAsync27 = false
    public var invokedMoveItemsToShareIdAsyncCount27 = 0
    public var invokedMoveItemsToShareIdAsyncParameters27: (items: [any ItemIdentifiable], toShareId: String)?
    public var invokedMoveItemsToShareIdAsyncParametersList27 = [(items: [any ItemIdentifiable], toShareId: String)]()

    public func move(items: [any ItemIdentifiable], toShareId: String) async throws {
        invokedMoveItemsToShareIdAsync27 = true
        invokedMoveItemsToShareIdAsyncCount27 += 1
        invokedMoveItemsToShareIdAsyncParameters27 = (items, toShareId)
        invokedMoveItemsToShareIdAsyncParametersList27.append((items, toShareId))
        if let error = moveItemsToShareIdThrowableError27 {
            throw error
        }
        closureMoveItemsToShareIdAsync27()
    }
    // MARK: - moveCurrentShareIdToShareId
    public var moveCurrentShareIdToShareIdThrowableError28: Error?
    public var closureMoveCurrentShareIdToShareIdAsync28: () -> () = {}
    public var invokedMoveCurrentShareIdToShareIdAsync28 = false
    public var invokedMoveCurrentShareIdToShareIdAsyncCount28 = 0
    public var invokedMoveCurrentShareIdToShareIdAsyncParameters28: (currentShareId: String, toShareId: String)?
    public var invokedMoveCurrentShareIdToShareIdAsyncParametersList28 = [(currentShareId: String, toShareId: String)]()
    public var stubbedMoveCurrentShareIdToShareIdAsyncResult28: [SymmetricallyEncryptedItem]!

    public func move(currentShareId: String, toShareId: String) async throws -> [SymmetricallyEncryptedItem] {
        invokedMoveCurrentShareIdToShareIdAsync28 = true
        invokedMoveCurrentShareIdToShareIdAsyncCount28 += 1
        invokedMoveCurrentShareIdToShareIdAsyncParameters28 = (currentShareId, toShareId)
        invokedMoveCurrentShareIdToShareIdAsyncParametersList28.append((currentShareId, toShareId))
        if let error = moveCurrentShareIdToShareIdThrowableError28 {
            throw error
        }
        closureMoveCurrentShareIdToShareIdAsync28()
        return stubbedMoveCurrentShareIdToShareIdAsyncResult28
    }
    // MARK: - deleteAllItemsLocally
    public var deleteAllItemsLocallyThrowableError29: Error?
    public var closureDeleteAllItemsLocallyAsync29: () -> () = {}
    public var invokedDeleteAllItemsLocallyAsync29 = false
    public var invokedDeleteAllItemsLocallyAsyncCount29 = 0

    public func deleteAllItemsLocally() async throws {
        invokedDeleteAllItemsLocallyAsync29 = true
        invokedDeleteAllItemsLocallyAsyncCount29 += 1
        if let error = deleteAllItemsLocallyThrowableError29 {
            throw error
        }
        closureDeleteAllItemsLocallyAsync29()
    }
    // MARK: - deleteAllCurrentUserItemsLocally
    public var deleteAllCurrentUserItemsLocallyThrowableError30: Error?
    public var closureDeleteAllCurrentUserItemsLocally: () -> () = {}
    public var invokedDeleteAllCurrentUserItemsLocallyfunction = false
    public var invokedDeleteAllCurrentUserItemsLocallyCount = 0

    public func deleteAllCurrentUserItemsLocally() async throws {
        invokedDeleteAllCurrentUserItemsLocallyfunction = true
        invokedDeleteAllCurrentUserItemsLocallyCount += 1
        if let error = deleteAllCurrentUserItemsLocallyThrowableError30 {
            throw error
        }
        closureDeleteAllCurrentUserItemsLocally()
    }
    // MARK: - deleteAllItemsLocallyShareId
    public var deleteAllItemsLocallyShareIdThrowableError31: Error?
    public var closureDeleteAllItemsLocallyShareIdAsync31: () -> () = {}
    public var invokedDeleteAllItemsLocallyShareIdAsync31 = false
    public var invokedDeleteAllItemsLocallyShareIdAsyncCount31 = 0
    public var invokedDeleteAllItemsLocallyShareIdAsyncParameters31: (shareId: String, Void)?
    public var invokedDeleteAllItemsLocallyShareIdAsyncParametersList31 = [(shareId: String, Void)]()

    public func deleteAllItemsLocally(shareId: String) async throws {
        invokedDeleteAllItemsLocallyShareIdAsync31 = true
        invokedDeleteAllItemsLocallyShareIdAsyncCount31 += 1
        invokedDeleteAllItemsLocallyShareIdAsyncParameters31 = (shareId, ())
        invokedDeleteAllItemsLocallyShareIdAsyncParametersList31.append((shareId, ()))
        if let error = deleteAllItemsLocallyShareIdThrowableError31 {
            throw error
        }
        closureDeleteAllItemsLocallyShareIdAsync31()
    }
    // MARK: - deleteItemsLocally
    public var deleteItemsLocallyItemIdsShareIdThrowableError32: Error?
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
        if let error = deleteItemsLocallyItemIdsShareIdThrowableError32 {
            throw error
        }
        closureDeleteItemsLocally()
    }
    // MARK: - getActiveLogInItems
    public var getActiveLogInItemsUserIdThrowableError33: Error?
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
        if let error = getActiveLogInItemsUserIdThrowableError33 {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
    // MARK: - pinItems
    public var pinItemsThrowableError34: Error?
    public var closurePinItems: () -> () = {}
    public var invokedPinItemsfunction = false
    public var invokedPinItemsCount = 0
    public var invokedPinItemsParameters: (items: [any ItemIdentifiable], Void)?
    public var invokedPinItemsParametersList = [(items: [any ItemIdentifiable], Void)]()

    public func pinItems(_ items: [any ItemIdentifiable]) async throws {
        invokedPinItemsfunction = true
        invokedPinItemsCount += 1
        invokedPinItemsParameters = (items, ())
        invokedPinItemsParametersList.append((items, ()))
        if let error = pinItemsThrowableError34 {
            throw error
        }
        closurePinItems()
    }
    // MARK: - unpinItems
    public var unpinItemsThrowableError35: Error?
    public var closureUnpinItems: () -> () = {}
    public var invokedUnpinItemsfunction = false
    public var invokedUnpinItemsCount = 0
    public var invokedUnpinItemsParameters: (items: [any ItemIdentifiable], Void)?
    public var invokedUnpinItemsParametersList = [(items: [any ItemIdentifiable], Void)]()

    public func unpinItems(_ items: [any ItemIdentifiable]) async throws {
        invokedUnpinItemsfunction = true
        invokedUnpinItemsCount += 1
        invokedUnpinItemsParameters = (items, ())
        invokedUnpinItemsParametersList.append((items, ()))
        if let error = unpinItemsThrowableError35 {
            throw error
        }
        closureUnpinItems()
    }
    // MARK: - getAllPinnedItems
    public var getAllPinnedItemsThrowableError36: Error?
    public var closureGetAllPinnedItems: () -> () = {}
    public var invokedGetAllPinnedItemsfunction = false
    public var invokedGetAllPinnedItemsCount = 0
    public var stubbedGetAllPinnedItemsResult: [SymmetricallyEncryptedItem]!

    public func getAllPinnedItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetAllPinnedItemsfunction = true
        invokedGetAllPinnedItemsCount += 1
        if let error = getAllPinnedItemsThrowableError36 {
            throw error
        }
        closureGetAllPinnedItems()
        return stubbedGetAllPinnedItemsResult
    }
    // MARK: - updateItemFlags
    public var updateItemFlagsFlagsShareIdItemIdThrowableError37: Error?
    public var closureUpdateItemFlags: () -> () = {}
    public var invokedUpdateItemFlagsfunction = false
    public var invokedUpdateItemFlagsCount = 0
    public var invokedUpdateItemFlagsParameters: (flags: [ItemFlag], shareId: String, itemId: String)?
    public var invokedUpdateItemFlagsParametersList = [(flags: [ItemFlag], shareId: String, itemId: String)]()

    public func updateItemFlags(flags: [ItemFlag], shareId: String, itemId: String) async throws {
        invokedUpdateItemFlagsfunction = true
        invokedUpdateItemFlagsCount += 1
        invokedUpdateItemFlagsParameters = (flags, shareId, itemId)
        invokedUpdateItemFlagsParametersList.append((flags, shareId, itemId))
        if let error = updateItemFlagsFlagsShareIdItemIdThrowableError37 {
            throw error
        }
        closureUpdateItemFlags()
    }
    // MARK: - getAllItemsContent
    public var getAllItemsContentItemsThrowableError38: Error?
    public var closureGetAllItemsContent: () -> () = {}
    public var invokedGetAllItemsContentfunction = false
    public var invokedGetAllItemsContentCount = 0
    public var invokedGetAllItemsContentParameters: (items: [any ItemIdentifiable], Void)?
    public var invokedGetAllItemsContentParametersList = [(items: [any ItemIdentifiable], Void)]()
    public var stubbedGetAllItemsContentResult: [ItemContent]!

    public func getAllItemsContent(items: [any ItemIdentifiable]) async throws -> [ItemContent] {
        invokedGetAllItemsContentfunction = true
        invokedGetAllItemsContentCount += 1
        invokedGetAllItemsContentParameters = (items, ())
        invokedGetAllItemsContentParametersList.append((items, ()))
        if let error = getAllItemsContentItemsThrowableError38 {
            throw error
        }
        closureGetAllItemsContent()
        return stubbedGetAllItemsContentResult
    }
    // MARK: - resetHistory
    public var resetHistoryThrowableError39: Error?
    public var closureResetHistory: () -> () = {}
    public var invokedResetHistoryfunction = false
    public var invokedResetHistoryCount = 0
    public var invokedResetHistoryParameters: (item: any ItemIdentifiable, Void)?
    public var invokedResetHistoryParametersList = [(item: any ItemIdentifiable, Void)]()

    public func resetHistory(_ item: any ItemIdentifiable) async throws {
        invokedResetHistoryfunction = true
        invokedResetHistoryCount += 1
        invokedResetHistoryParameters = (item, ())
        invokedResetHistoryParametersList.append((item, ()))
        if let error = resetHistoryThrowableError39 {
            throw error
        }
        closureResetHistory()
    }
    // MARK: - importLogins
    public var importLoginsUserIdShareIdLoginsThrowableError40: Error?
    public var closureImportLogins: () -> () = {}
    public var invokedImportLoginsfunction = false
    public var invokedImportLoginsCount = 0
    public var invokedImportLoginsParameters: (userId: String, shareId: String, logins: [CsvLogin])?
    public var invokedImportLoginsParametersList = [(userId: String, shareId: String, logins: [CsvLogin])]()

    public func importLogins(userId: String, shareId: String, logins: [CsvLogin]) async throws {
        invokedImportLoginsfunction = true
        invokedImportLoginsCount += 1
        invokedImportLoginsParameters = (userId, shareId, logins)
        invokedImportLoginsParametersList.append((userId, shareId, logins))
        if let error = importLoginsUserIdShareIdLoginsThrowableError40 {
            throw error
        }
        closureImportLogins()
    }
    // MARK: - totpCreationDateThreshold
    public var totpCreationDateThresholdNumberOfTotpThrowableError41: Error?
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
        if let error = totpCreationDateThresholdNumberOfTotpThrowableError41 {
            throw error
        }
        closureTotpCreationDateThreshold()
        return stubbedTotpCreationDateThresholdResult
    }
}
