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
    public nonisolated(unsafe) var stubbedCurrentlyPinnedItems: CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never>!

    public var currentlyPinnedItems: CurrentValueSubject<[SymmetricallyEncryptedItem]?, Never> {
         get {
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
    public nonisolated(unsafe) var stubbedItemsWereUpdated: CurrentValueSubject<Void, Never>!

    public var itemsWereUpdated: CurrentValueSubject<Void, Never> {
         get {
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
    public var invokedGetItemsShareIdFolderIdStateAsyncParameters5: (shareId: String, folderId: String?, state: ItemState)?
    public var invokedGetItemsShareIdFolderIdStateAsyncParametersList5 = [(shareId: String, folderId: String?, state: ItemState)]()
    public var stubbedGetItemsShareIdFolderIdStateAsyncResult5: [SymmetricallyEncryptedItem]!

    public func getItems(shareId: String, folderId: String?, state: ItemState) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsShareIdFolderIdStateAsync5 = true
        invokedGetItemsShareIdFolderIdStateAsyncCount5 += 1
        invokedGetItemsShareIdFolderIdStateAsyncParameters5 = (shareId, folderId, state)
        if let error = getItemsShareIdFolderIdStateThrowableError5 {
            throw error
        }
        closureGetItemsShareIdFolderIdStateAsync5()
        return stubbedGetItemsShareIdFolderIdStateAsyncResult5
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
        if let error = getItemShareIdItemIdThrowableError6 {
            throw error
        }
        closureGetItem()
        return stubbedGetItemResult
    }
    // MARK: - getItemsIds
    public var getItemsThrowableError7: Error?
    public var closureGetItemsIdsAsync7: () -> () = {}
    public var invokedGetItemsIdsAsync7 = false
    public var invokedGetItemsIdsAsyncCount7 = 0
    public var invokedGetItemsIdsAsyncParameters7: (ids: [any ItemIdentifiable], Void)?
    public var invokedGetItemsIdsAsyncParametersList7 = [(ids: [any ItemIdentifiable], Void)]()
    public var stubbedGetItemsIdsAsyncResult7: [SymmetricallyEncryptedItem]!

    public func getItems(_ ids: [any ItemIdentifiable]) async throws -> [SymmetricallyEncryptedItem] {
        invokedGetItemsIdsAsync7 = true
        invokedGetItemsIdsAsyncCount7 += 1
        invokedGetItemsIdsAsyncParameters7 = (ids, ())
        if let error = getItemsThrowableError7 {
            throw error
        }
        closureGetItemsIdsAsync7()
        return stubbedGetItemsIdsAsyncResult7
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
    // MARK: - changeAliasStatus
    public var changeAliasStatusUserIdItemsEnabledThrowableError9: Error?
    public var closureChangeAliasStatus: () -> () = {}
    public var invokedChangeAliasStatusfunction = false
    public var invokedChangeAliasStatusCount = 0
    public var invokedChangeAliasStatusParameters: (userId: String, items: [any ItemIdentifiable], enabled: Bool)?
    public var invokedChangeAliasStatusParametersList = [(userId: String, items: [any ItemIdentifiable], enabled: Bool)]()

    public func changeAliasStatus(userId: String, items: [any ItemIdentifiable], enabled: Bool) async throws {
        invokedChangeAliasStatusfunction = true
        invokedChangeAliasStatusCount += 1
        invokedChangeAliasStatusParameters = (userId, items, enabled)
        if let error = changeAliasStatusUserIdItemsEnabledThrowableError9 {
            throw error
        }
        closureChangeAliasStatus()
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
        if let error = getUnsyncedSimpleLoginNoteAliasesUserIdThrowableError10 {
            throw error
        }
        closureGetUnsyncedSimpleLoginNoteAliases()
        return stubbedGetUnsyncedSimpleLoginNoteAliasesResult
    }
    // MARK: - getItemContent
    public var getItemContentShareIdItemIdThrowableError11: Error?
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
        if let error = getItemContentShareIdItemIdThrowableError11 {
            throw error
        }
        closureGetItemContent()
        return stubbedGetItemContentResult
    }
    // MARK: - getItemRevisions
    public var getItemRevisionsUserIdShareIdItemIdLastTokenThrowableError12: Error?
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
        if let error = getItemRevisionsUserIdShareIdItemIdLastTokenThrowableError12 {
            throw error
        }
        closureGetItemRevisions()
        return stubbedGetItemRevisionsResult
    }
    // MARK: - refreshItems
    public var refreshItemsUserIdShareIdEventStreamThrowableError13: Error?
    public var closureRefreshItems: () -> () = {}
    public var invokedRefreshItemsfunction = false
    public var invokedRefreshItemsCount = 0
    public var invokedRefreshItemsParameters: (userId: String, shareId: String, eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?)?
    public var invokedRefreshItemsParametersList = [(userId: String, shareId: String, eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?)]()

    public func refreshItems(userId: String, shareId: String, eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?) async throws {
        invokedRefreshItemsfunction = true
        invokedRefreshItemsCount += 1
        invokedRefreshItemsParameters = (userId, shareId, eventStream)
        if let error = refreshItemsUserIdShareIdEventStreamThrowableError13 {
            throw error
        }
        closureRefreshItems()
    }
    // MARK: - refreshItem
    public var refreshItemUserIdShareIdItemIdEventTokenThrowableError14: Error?
    public var closureRefreshItem: () -> () = {}
    public var invokedRefreshItemfunction = false
    public var invokedRefreshItemCount = 0
    public var invokedRefreshItemParameters: (userId: String, shareId: String, itemId: String, eventToken: String)?
    public var invokedRefreshItemParametersList = [(userId: String, shareId: String, itemId: String, eventToken: String)]()

    public func refreshItem(userId: String, shareId: String, itemId: String, eventToken: String) async throws {
        invokedRefreshItemfunction = true
        invokedRefreshItemCount += 1
        invokedRefreshItemParameters = (userId, shareId, itemId, eventToken)
        if let error = refreshItemUserIdShareIdItemIdEventTokenThrowableError14 {
            throw error
        }
        closureRefreshItem()
    }
    // MARK: - createItem
    public var createItemUserIdItemContentShareIdFolderIdThrowableError15: Error?
    public var closureCreateItem: () -> () = {}
    public var invokedCreateItemfunction = false
    public var invokedCreateItemCount = 0
    public var invokedCreateItemParameters: (userId: String, itemContent: any ProtobufableItemContentProtocol, shareId: String, folderId: String?)?
    public var invokedCreateItemParametersList = [(userId: String, itemContent: any ProtobufableItemContentProtocol, shareId: String, folderId: String?)]()
    public var stubbedCreateItemResult: SymmetricallyEncryptedItem!

    public func createItem(userId: String, itemContent: any ProtobufableItemContentProtocol, shareId: String, folderId: String?) async throws -> SymmetricallyEncryptedItem {
        invokedCreateItemfunction = true
        invokedCreateItemCount += 1
        invokedCreateItemParameters = (userId, itemContent, shareId, folderId)
        if let error = createItemUserIdItemContentShareIdFolderIdThrowableError15 {
            throw error
        }
        closureCreateItem()
        return stubbedCreateItemResult
    }
    // MARK: - createAlias
    public var createAliasUserIdInfoItemContentShareIdFolderIdThrowableError16: Error?
    public var closureCreateAlias: () -> () = {}
    public var invokedCreateAliasfunction = false
    public var invokedCreateAliasCount = 0
    public var invokedCreateAliasParameters: (userId: String, info: AliasCreationInfo, itemContent: any ProtobufableItemContentProtocol, shareId: String, folderId: String?)?
    public var invokedCreateAliasParametersList = [(userId: String, info: AliasCreationInfo, itemContent: any ProtobufableItemContentProtocol, shareId: String, folderId: String?)]()
    public var stubbedCreateAliasResult: SymmetricallyEncryptedItem!

    public func createAlias(userId: String, info: AliasCreationInfo, itemContent: any ProtobufableItemContentProtocol, shareId: String, folderId: String?) async throws -> SymmetricallyEncryptedItem {
        invokedCreateAliasfunction = true
        invokedCreateAliasCount += 1
        invokedCreateAliasParameters = (userId, info, itemContent, shareId, folderId)
        if let error = createAliasUserIdInfoItemContentShareIdFolderIdThrowableError16 {
            throw error
        }
        closureCreateAlias()
        return stubbedCreateAliasResult
    }
    // MARK: - createPendingAliasesItem
    public var createPendingAliasesItemUserIdShareIdFolderIdItemsContentThrowableError17: Error?
    public var closureCreatePendingAliasesItem: () -> () = {}
    public var invokedCreatePendingAliasesItemfunction = false
    public var invokedCreatePendingAliasesItemCount = 0
    public var invokedCreatePendingAliasesItemParameters: (userId: String, shareId: String, folderId: String?, itemsContent: [String: any ProtobufableItemContentProtocol])?
    public var invokedCreatePendingAliasesItemParametersList = [(userId: String, shareId: String, folderId: String?, itemsContent: [String: any ProtobufableItemContentProtocol])]()
    public var stubbedCreatePendingAliasesItemResult: [SymmetricallyEncryptedItem]!

    public func createPendingAliasesItem(userId: String, shareId: String, folderId: String?, itemsContent: [String: any ProtobufableItemContentProtocol]) async throws -> [SymmetricallyEncryptedItem] {
        invokedCreatePendingAliasesItemfunction = true
        invokedCreatePendingAliasesItemCount += 1
        invokedCreatePendingAliasesItemParameters = (userId, shareId, folderId, itemsContent)
        if let error = createPendingAliasesItemUserIdShareIdFolderIdItemsContentThrowableError17 {
            throw error
        }
        closureCreatePendingAliasesItem()
        return stubbedCreatePendingAliasesItemResult
    }
    // MARK: - createAliasAndOtherItem
    public var createAliasAndOtherItemUserIdInfoAliasItemContentOtherItemContentShareIdFolderIdThrowableError18: Error?
    public var closureCreateAliasAndOtherItem: () -> () = {}
    public var invokedCreateAliasAndOtherItemfunction = false
    public var invokedCreateAliasAndOtherItemCount = 0
    public var invokedCreateAliasAndOtherItemParameters: (userId: String, info: AliasCreationInfo, aliasItemContent: any ProtobufableItemContentProtocol, otherItemContent: any ProtobufableItemContentProtocol, shareId: String, folderId: String?)?
    public var invokedCreateAliasAndOtherItemParametersList = [(userId: String, info: AliasCreationInfo, aliasItemContent: any ProtobufableItemContentProtocol, otherItemContent: any ProtobufableItemContentProtocol, shareId: String, folderId: String?)]()
    public var stubbedCreateAliasAndOtherItemResult: (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem)!

    public func createAliasAndOtherItem(userId: String, info: AliasCreationInfo, aliasItemContent: any ProtobufableItemContentProtocol, otherItemContent: any ProtobufableItemContentProtocol, shareId: String, folderId: String?) async throws -> (SymmetricallyEncryptedItem, SymmetricallyEncryptedItem) {
        invokedCreateAliasAndOtherItemfunction = true
        invokedCreateAliasAndOtherItemCount += 1
        invokedCreateAliasAndOtherItemParameters = (userId, info, aliasItemContent, otherItemContent, shareId, folderId)
        if let error = createAliasAndOtherItemUserIdInfoAliasItemContentOtherItemContentShareIdFolderIdThrowableError18 {
            throw error
        }
        closureCreateAliasAndOtherItem()
        return stubbedCreateAliasAndOtherItemResult
    }
    // MARK: - trashItemsItems
    public var trashItemsThrowableError19: Error?
    public var closureTrashItemsItemsAsync19: () -> () = {}
    public var invokedTrashItemsItemsAsync19 = false
    public var invokedTrashItemsItemsAsyncCount19 = 0
    public var invokedTrashItemsItemsAsyncParameters19: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedTrashItemsItemsAsyncParametersList19 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func trashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedTrashItemsItemsAsync19 = true
        invokedTrashItemsItemsAsyncCount19 += 1
        invokedTrashItemsItemsAsyncParameters19 = (items, ())
        if let error = trashItemsThrowableError19 {
            throw error
        }
        closureTrashItemsItemsAsync19()
    }
    // MARK: - trashItemsItems
    public var trashItemsThrowableError20: Error?
    public var closureTrashItemsItemsAsync20: () -> () = {}
    public var invokedTrashItemsItemsAsync20 = false
    public var invokedTrashItemsItemsAsyncCount20 = 0
    public var invokedTrashItemsItemsAsyncParameters20: (items: [any ItemIdentifiable], Void)?
    public var invokedTrashItemsItemsAsyncParametersList20 = [(items: [any ItemIdentifiable], Void)]()

    public func trashItems(_ items: [any ItemIdentifiable]) async throws {
        invokedTrashItemsItemsAsync20 = true
        invokedTrashItemsItemsAsyncCount20 += 1
        invokedTrashItemsItemsAsyncParameters20 = (items, ())
        if let error = trashItemsThrowableError20 {
            throw error
        }
        closureTrashItemsItemsAsync20()
    }
    // MARK: - untrashItemsItems
    public var untrashItemsThrowableError21: Error?
    public var closureUntrashItemsItemsAsync21: () -> () = {}
    public var invokedUntrashItemsItemsAsync21 = false
    public var invokedUntrashItemsItemsAsyncCount21 = 0
    public var invokedUntrashItemsItemsAsyncParameters21: (items: [SymmetricallyEncryptedItem], Void)?
    public var invokedUntrashItemsItemsAsyncParametersList21 = [(items: [SymmetricallyEncryptedItem], Void)]()

    public func untrashItems(_ items: [SymmetricallyEncryptedItem]) async throws {
        invokedUntrashItemsItemsAsync21 = true
        invokedUntrashItemsItemsAsyncCount21 += 1
        invokedUntrashItemsItemsAsyncParameters21 = (items, ())
        if let error = untrashItemsThrowableError21 {
            throw error
        }
        closureUntrashItemsItemsAsync21()
    }
    // MARK: - untrashItemsItems
    public var untrashItemsThrowableError22: Error?
    public var closureUntrashItemsItemsAsync22: () -> () = {}
    public var invokedUntrashItemsItemsAsync22 = false
    public var invokedUntrashItemsItemsAsyncCount22 = 0
    public var invokedUntrashItemsItemsAsyncParameters22: (items: [any ItemIdentifiable], Void)?
    public var invokedUntrashItemsItemsAsyncParametersList22 = [(items: [any ItemIdentifiable], Void)]()

    public func untrashItems(_ items: [any ItemIdentifiable]) async throws {
        invokedUntrashItemsItemsAsync22 = true
        invokedUntrashItemsItemsAsyncCount22 += 1
        invokedUntrashItemsItemsAsyncParameters22 = (items, ())
        if let error = untrashItemsThrowableError22 {
            throw error
        }
        closureUntrashItemsItemsAsync22()
    }
    // MARK: - deleteItems
    public var deleteItemsUserIdSkipTrashThrowableError23: Error?
    public var closureDeleteItems: () -> () = {}
    public var invokedDeleteItemsfunction = false
    public var invokedDeleteItemsCount = 0
    public var invokedDeleteItemsParameters: (userId: String, items: [SymmetricallyEncryptedItem], skipTrash: Bool)?
    public var invokedDeleteItemsParametersList = [(userId: String, items: [SymmetricallyEncryptedItem], skipTrash: Bool)]()

    public func deleteItems(userId: String, _ items: [SymmetricallyEncryptedItem], skipTrash: Bool) async throws {
        invokedDeleteItemsfunction = true
        invokedDeleteItemsCount += 1
        invokedDeleteItemsParameters = (userId, items, skipTrash)
        if let error = deleteItemsUserIdSkipTrashThrowableError23 {
            throw error
        }
        closureDeleteItems()
    }
    // MARK: - delete
    public var deleteUserIdItemsThrowableError24: Error?
    public var closureDelete: () -> () = {}
    public var invokedDeletefunction = false
    public var invokedDeleteCount = 0
    public var invokedDeleteParameters: (userId: String, items: [any ItemIdentifiable])?
    public var invokedDeleteParametersList = [(userId: String, items: [any ItemIdentifiable])]()

    public func delete(userId: String, items: [any ItemIdentifiable]) async throws {
        invokedDeletefunction = true
        invokedDeleteCount += 1
        invokedDeleteParameters = (userId, items)
        if let error = deleteUserIdItemsThrowableError24 {
            throw error
        }
        closureDelete()
    }
    // MARK: - updateItem
    public var updateItemUserIdOldItemNewItemContentShareIdSlNoteThrowableError25: Error?
    public var closureUpdateItem: () -> () = {}
    public var invokedUpdateItemfunction = false
    public var invokedUpdateItemCount = 0
    public var invokedUpdateItemParameters: (userId: String, oldItem: Item, newItemContent: any ProtobufableItemContentProtocol, shareId: String, slNote: String?)?
    public var invokedUpdateItemParametersList = [(userId: String, oldItem: Item, newItemContent: any ProtobufableItemContentProtocol, shareId: String, slNote: String?)]()
    public var stubbedUpdateItemResult: SymmetricallyEncryptedItem!

    public func updateItem(userId: String, oldItem: Item, newItemContent: any ProtobufableItemContentProtocol, shareId: String, slNote: String?) async throws -> SymmetricallyEncryptedItem {
        invokedUpdateItemfunction = true
        invokedUpdateItemCount += 1
        invokedUpdateItemParameters = (userId, oldItem, newItemContent, shareId, slNote)
        if let error = updateItemUserIdOldItemNewItemContentShareIdSlNoteThrowableError25 {
            throw error
        }
        closureUpdateItem()
        return stubbedUpdateItemResult
    }
    // MARK: - upsertItems
    public var upsertItemsUserIdItemsShareIdThrowableError26: Error?
    public var closureUpsertItems: () -> () = {}
    public var invokedUpsertItemsfunction = false
    public var invokedUpsertItemsCount = 0
    public var invokedUpsertItemsParameters: (userId: String, items: [Item], shareId: String)?
    public var invokedUpsertItemsParametersList = [(userId: String, items: [Item], shareId: String)]()

    public func upsertItems(userId: String, items: [Item], shareId: String) async throws {
        invokedUpsertItemsfunction = true
        invokedUpsertItemsCount += 1
        invokedUpsertItemsParameters = (userId, items, shareId)
        if let error = upsertItemsUserIdItemsShareIdThrowableError26 {
            throw error
        }
        closureUpsertItems()
    }
    // MARK: - update
    public var updateLastUseItemsShareIdThrowableError27: Error?
    public var closureUpdate: () -> () = {}
    public var invokedUpdatefunction = false
    public var invokedUpdateCount = 0
    public var invokedUpdateParameters: (lastUseItems: [LastUseItem], shareId: String)?
    public var invokedUpdateParametersList = [(lastUseItems: [LastUseItem], shareId: String)]()

    public func update(lastUseItems: [LastUseItem], shareId: String) async throws {
        invokedUpdatefunction = true
        invokedUpdateCount += 1
        invokedUpdateParameters = (lastUseItems, shareId)
        if let error = updateLastUseItemsShareIdThrowableError27 {
            throw error
        }
        closureUpdate()
    }
    // MARK: - updateLastUseTime
    public var updateLastUseTimeUserIdItemDateThrowableError28: Error?
    public var closureUpdateLastUseTime: () -> () = {}
    public var invokedUpdateLastUseTimefunction = false
    public var invokedUpdateLastUseTimeCount = 0
    public var invokedUpdateLastUseTimeParameters: (userId: String, item: any ItemIdentifiable, date: Date)?
    public var invokedUpdateLastUseTimeParametersList = [(userId: String, item: any ItemIdentifiable, date: Date)]()

    public func updateLastUseTime(userId: String, item: any ItemIdentifiable, date: Date) async throws {
        invokedUpdateLastUseTimefunction = true
        invokedUpdateLastUseTimeCount += 1
        invokedUpdateLastUseTimeParameters = (userId, item, date)
        if let error = updateLastUseTimeUserIdItemDateThrowableError28 {
            throw error
        }
        closureUpdateLastUseTime()
    }
    // MARK: - updateCachedAliasInfo
    public var updateCachedAliasInfoUserIdItemsAliasesThrowableError29: Error?
    public var closureUpdateCachedAliasInfo: () -> () = {}
    public var invokedUpdateCachedAliasInfofunction = false
    public var invokedUpdateCachedAliasInfoCount = 0
    public var invokedUpdateCachedAliasInfoParameters: (userId: String, items: [SymmetricallyEncryptedItem], aliases: [Alias])?
    public var invokedUpdateCachedAliasInfoParametersList = [(userId: String, items: [SymmetricallyEncryptedItem], aliases: [Alias])]()

    public func updateCachedAliasInfo(userId: String, items: [SymmetricallyEncryptedItem], aliases: [Alias]) async throws {
        invokedUpdateCachedAliasInfofunction = true
        invokedUpdateCachedAliasInfoCount += 1
        invokedUpdateCachedAliasInfoParameters = (userId, items, aliases)
        if let error = updateCachedAliasInfoUserIdItemsAliasesThrowableError29 {
            throw error
        }
        closureUpdateCachedAliasInfo()
    }
    // MARK: - moveItemsToShareIdDestinationFolderId
    public var moveItemsToShareIdDestinationFolderIdThrowableError30: Error?
    public var closureMoveItemsToShareIdDestinationFolderIdAsync30: () -> () = {}
    public var invokedMoveItemsToShareIdDestinationFolderIdAsync30 = false
    public var invokedMoveItemsToShareIdDestinationFolderIdAsyncCount30 = 0
    public var invokedMoveItemsToShareIdDestinationFolderIdAsyncParameters30: (items: [any ItemIdentifiable], toShareId: String, destinationFolderId: String?)?
    public var invokedMoveItemsToShareIdDestinationFolderIdAsyncParametersList30 = [(items: [any ItemIdentifiable], toShareId: String, destinationFolderId: String?)]()

    public func move(items: [any ItemIdentifiable], toShareId: String, destinationFolderId: String?) async throws {
        invokedMoveItemsToShareIdDestinationFolderIdAsync30 = true
        invokedMoveItemsToShareIdDestinationFolderIdAsyncCount30 += 1
        invokedMoveItemsToShareIdDestinationFolderIdAsyncParameters30 = (items, toShareId, destinationFolderId)
        if let error = moveItemsToShareIdDestinationFolderIdThrowableError30 {
            throw error
        }
        closureMoveItemsToShareIdDestinationFolderIdAsync30()
    }
    // MARK: - moveCurrentShareIdToShareIdDestinationFolderId
    public var moveCurrentShareIdToShareIdDestinationFolderIdThrowableError31: Error?
    public var closureMoveCurrentShareIdToShareIdDestinationFolderIdAsync31: () -> () = {}
    public var invokedMoveCurrentShareIdToShareIdDestinationFolderIdAsync31 = false
    public var invokedMoveCurrentShareIdToShareIdDestinationFolderIdAsyncCount31 = 0
    public var invokedMoveCurrentShareIdToShareIdDestinationFolderIdAsyncParameters31: (currentShareId: String, toShareId: String, destinationFolderId: String?)?
    public var invokedMoveCurrentShareIdToShareIdDestinationFolderIdAsyncParametersList31 = [(currentShareId: String, toShareId: String, destinationFolderId: String?)]()

    public func move(currentShareId: String, toShareId: String, destinationFolderId: String?) async throws {
        invokedMoveCurrentShareIdToShareIdDestinationFolderIdAsync31 = true
        invokedMoveCurrentShareIdToShareIdDestinationFolderIdAsyncCount31 += 1
        invokedMoveCurrentShareIdToShareIdDestinationFolderIdAsyncParameters31 = (currentShareId, toShareId, destinationFolderId)
        if let error = moveCurrentShareIdToShareIdDestinationFolderIdThrowableError31 {
            throw error
        }
        closureMoveCurrentShareIdToShareIdDestinationFolderIdAsync31()
    }
    // MARK: - deleteAllItemsLocally
    public var deleteAllItemsLocallyThrowableError32: Error?
    public var closureDeleteAllItemsLocallyAsync32: () -> () = {}
    public var invokedDeleteAllItemsLocallyAsync32 = false
    public var invokedDeleteAllItemsLocallyAsyncCount32 = 0

    public func deleteAllItemsLocally() async throws {
        invokedDeleteAllItemsLocallyAsync32 = true
        invokedDeleteAllItemsLocallyAsyncCount32 += 1
        if let error = deleteAllItemsLocallyThrowableError32 {
            throw error
        }
        closureDeleteAllItemsLocallyAsync32()
    }
    // MARK: - deleteAllCurrentUserItemsLocally
    public var deleteAllCurrentUserItemsLocallyUserIdThrowableError33: Error?
    public var closureDeleteAllCurrentUserItemsLocally: () -> () = {}
    public var invokedDeleteAllCurrentUserItemsLocallyfunction = false
    public var invokedDeleteAllCurrentUserItemsLocallyCount = 0
    public var invokedDeleteAllCurrentUserItemsLocallyParameters: (userId: String, Void)?
    public var invokedDeleteAllCurrentUserItemsLocallyParametersList = [(userId: String, Void)]()

    public func deleteAllCurrentUserItemsLocally(userId: String) async throws {
        invokedDeleteAllCurrentUserItemsLocallyfunction = true
        invokedDeleteAllCurrentUserItemsLocallyCount += 1
        invokedDeleteAllCurrentUserItemsLocallyParameters = (userId, ())
        if let error = deleteAllCurrentUserItemsLocallyUserIdThrowableError33 {
            throw error
        }
        closureDeleteAllCurrentUserItemsLocally()
    }
    // MARK: - deleteAllItemsLocallyShareId
    public var deleteAllItemsLocallyShareIdThrowableError34: Error?
    public var closureDeleteAllItemsLocallyShareIdAsync34: () -> () = {}
    public var invokedDeleteAllItemsLocallyShareIdAsync34 = false
    public var invokedDeleteAllItemsLocallyShareIdAsyncCount34 = 0
    public var invokedDeleteAllItemsLocallyShareIdAsyncParameters34: (shareId: String, Void)?
    public var invokedDeleteAllItemsLocallyShareIdAsyncParametersList34 = [(shareId: String, Void)]()

    public func deleteAllItemsLocally(shareId: String) async throws {
        invokedDeleteAllItemsLocallyShareIdAsync34 = true
        invokedDeleteAllItemsLocallyShareIdAsyncCount34 += 1
        invokedDeleteAllItemsLocallyShareIdAsyncParameters34 = (shareId, ())
        if let error = deleteAllItemsLocallyShareIdThrowableError34 {
            throw error
        }
        closureDeleteAllItemsLocallyShareIdAsync34()
    }
    // MARK: - deleteItemsLocallyItemIdsShareId
    public var deleteItemsLocallyItemIdsShareIdThrowableError35: Error?
    public var closureDeleteItemsLocallyItemIdsShareIdAsync35: () -> () = {}
    public var invokedDeleteItemsLocallyItemIdsShareIdAsync35 = false
    public var invokedDeleteItemsLocallyItemIdsShareIdAsyncCount35 = 0
    public var invokedDeleteItemsLocallyItemIdsShareIdAsyncParameters35: (itemIds: [String], shareId: String)?
    public var invokedDeleteItemsLocallyItemIdsShareIdAsyncParametersList35 = [(itemIds: [String], shareId: String)]()

    public func deleteItemsLocally(itemIds: [String], shareId: String) async throws {
        invokedDeleteItemsLocallyItemIdsShareIdAsync35 = true
        invokedDeleteItemsLocallyItemIdsShareIdAsyncCount35 += 1
        invokedDeleteItemsLocallyItemIdsShareIdAsyncParameters35 = (itemIds, shareId)
        if let error = deleteItemsLocallyItemIdsShareIdThrowableError35 {
            throw error
        }
        closureDeleteItemsLocallyItemIdsShareIdAsync35()
    }
    // MARK: - deleteItemsLocallyItems
    public var deleteItemsLocallyItemsThrowableError36: Error?
    public var closureDeleteItemsLocallyItemsAsync36: () -> () = {}
    public var invokedDeleteItemsLocallyItemsAsync36 = false
    public var invokedDeleteItemsLocallyItemsAsyncCount36 = 0
    public var invokedDeleteItemsLocallyItemsAsyncParameters36: (items: [any ItemIdentifiable], Void)?
    public var invokedDeleteItemsLocallyItemsAsyncParametersList36 = [(items: [any ItemIdentifiable], Void)]()

    public func deleteItemsLocally(items: [any ItemIdentifiable]) async throws {
        invokedDeleteItemsLocallyItemsAsync36 = true
        invokedDeleteItemsLocallyItemsAsyncCount36 += 1
        invokedDeleteItemsLocallyItemsAsyncParameters36 = (items, ())
        if let error = deleteItemsLocallyItemsThrowableError36 {
            throw error
        }
        closureDeleteItemsLocallyItemsAsync36()
    }
    // MARK: - getActiveLogInItems
    public var getActiveLogInItemsUserIdThrowableError37: Error?
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
        if let error = getActiveLogInItemsUserIdThrowableError37 {
            throw error
        }
        closureGetActiveLogInItems()
        return stubbedGetActiveLogInItemsResult
    }
    // MARK: - pinItems
    public var pinItemsThrowableError38: Error?
    public var closurePinItems: () -> () = {}
    public var invokedPinItemsfunction = false
    public var invokedPinItemsCount = 0
    public var invokedPinItemsParameters: (items: [any ItemIdentifiable], Void)?
    public var invokedPinItemsParametersList = [(items: [any ItemIdentifiable], Void)]()

    public func pinItems(_ items: [any ItemIdentifiable]) async throws {
        invokedPinItemsfunction = true
        invokedPinItemsCount += 1
        invokedPinItemsParameters = (items, ())
        if let error = pinItemsThrowableError38 {
            throw error
        }
        closurePinItems()
    }
    // MARK: - unpinItems
    public var unpinItemsThrowableError39: Error?
    public var closureUnpinItems: () -> () = {}
    public var invokedUnpinItemsfunction = false
    public var invokedUnpinItemsCount = 0
    public var invokedUnpinItemsParameters: (items: [any ItemIdentifiable], Void)?
    public var invokedUnpinItemsParametersList = [(items: [any ItemIdentifiable], Void)]()

    public func unpinItems(_ items: [any ItemIdentifiable]) async throws {
        invokedUnpinItemsfunction = true
        invokedUnpinItemsCount += 1
        invokedUnpinItemsParameters = (items, ())
        if let error = unpinItemsThrowableError39 {
            throw error
        }
        closureUnpinItems()
    }
    // MARK: - getAllPinnedItems
    public var getAllPinnedItemsThrowableError40: Error?
    public var closureGetAllPinnedItems: () -> () = {}
    public var invokedGetAllPinnedItemsfunction = false
    public var invokedGetAllPinnedItemsCount = 0
    public var stubbedGetAllPinnedItemsResult: [SymmetricallyEncryptedItem]!

    public func getAllPinnedItems() async throws -> [SymmetricallyEncryptedItem] {
        invokedGetAllPinnedItemsfunction = true
        invokedGetAllPinnedItemsCount += 1
        if let error = getAllPinnedItemsThrowableError40 {
            throw error
        }
        closureGetAllPinnedItems()
        return stubbedGetAllPinnedItemsResult
    }
    // MARK: - refreshPinnedItemDataStream
    public var refreshPinnedItemDataStreamThrowableError41: Error?
    public var closureRefreshPinnedItemDataStream: () -> () = {}
    public var invokedRefreshPinnedItemDataStreamfunction = false
    public var invokedRefreshPinnedItemDataStreamCount = 0

    public func refreshPinnedItemDataStream() async throws {
        invokedRefreshPinnedItemDataStreamfunction = true
        invokedRefreshPinnedItemDataStreamCount += 1
        if let error = refreshPinnedItemDataStreamThrowableError41 {
            throw error
        }
        closureRefreshPinnedItemDataStream()
    }
    // MARK: - updateItemFlags
    public var updateItemFlagsFlagsShareIdItemIdThrowableError42: Error?
    public var closureUpdateItemFlags: () -> () = {}
    public var invokedUpdateItemFlagsfunction = false
    public var invokedUpdateItemFlagsCount = 0
    public var invokedUpdateItemFlagsParameters: (flags: [ItemFlag], shareId: String, itemId: String)?
    public var invokedUpdateItemFlagsParametersList = [(flags: [ItemFlag], shareId: String, itemId: String)]()

    public func updateItemFlags(flags: [ItemFlag], shareId: String, itemId: String) async throws {
        invokedUpdateItemFlagsfunction = true
        invokedUpdateItemFlagsCount += 1
        invokedUpdateItemFlagsParameters = (flags, shareId, itemId)
        if let error = updateItemFlagsFlagsShareIdItemIdThrowableError42 {
            throw error
        }
        closureUpdateItemFlags()
    }
    // MARK: - getAllItemsContent
    public var getAllItemsContentItemsThrowableError43: Error?
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
        if let error = getAllItemsContentItemsThrowableError43 {
            throw error
        }
        closureGetAllItemsContent()
        return stubbedGetAllItemsContentResult
    }
    // MARK: - resetHistory
    public var resetHistoryThrowableError44: Error?
    public var closureResetHistory: () -> () = {}
    public var invokedResetHistoryfunction = false
    public var invokedResetHistoryCount = 0
    public var invokedResetHistoryParameters: (item: any ItemIdentifiable, Void)?
    public var invokedResetHistoryParametersList = [(item: any ItemIdentifiable, Void)]()

    public func resetHistory(_ item: any ItemIdentifiable) async throws {
        invokedResetHistoryfunction = true
        invokedResetHistoryCount += 1
        invokedResetHistoryParameters = (item, ())
        if let error = resetHistoryThrowableError44 {
            throw error
        }
        closureResetHistory()
    }
    // MARK: - importLogins
    public var importLoginsUserIdShareIdLoginsThrowableError45: Error?
    public var closureImportLogins: () -> () = {}
    public var invokedImportLoginsfunction = false
    public var invokedImportLoginsCount = 0
    public var invokedImportLoginsParameters: (userId: String, shareId: String, logins: [CsvLogin])?
    public var invokedImportLoginsParametersList = [(userId: String, shareId: String, logins: [CsvLogin])]()

    public func importLogins(userId: String, shareId: String, logins: [CsvLogin]) async throws {
        invokedImportLoginsfunction = true
        invokedImportLoginsCount += 1
        invokedImportLoginsParameters = (userId, shareId, logins)
        if let error = importLoginsUserIdShareIdLoginsThrowableError45 {
            throw error
        }
        closureImportLogins()
    }
    // MARK: - totpCreationDateThreshold
    public var totpCreationDateThresholdNumberOfTotpThrowableError46: Error?
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
        if let error = totpCreationDateThresholdNumberOfTotpThrowableError46 {
            throw error
        }
        closureTotpCreationDateThreshold()
        return stubbedTotpCreationDateThresholdResult
    }
}
