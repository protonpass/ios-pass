// Generated using Sourcery 2.2.5 — https://github.com/krzysztofzablocki/Sourcery
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
import Entities
import Foundation

public final class RemoteItemDatasourceProtocolMock: @unchecked Sendable, RemoteItemDatasourceProtocol {

    public init() {}

    // MARK: - getItems
    public var getItemsUserIdShareIdEventStreamThrowableError1: Error?
    public var closureGetItems: () -> () = {}
    public var invokedGetItemsfunction = false
    public var invokedGetItemsCount = 0
    public var invokedGetItemsParameters: (userId: String, shareId: String, eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?)?
    public var invokedGetItemsParametersList = [(userId: String, shareId: String, eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?)]()
    public var stubbedGetItemsResult: [Item]!

    public func getItems(userId: String, shareId: String, eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?) async throws -> [Item] {
        invokedGetItemsfunction = true
        invokedGetItemsCount += 1
        invokedGetItemsParameters = (userId, shareId, eventStream)
        invokedGetItemsParametersList.append((userId, shareId, eventStream))
        if let error = getItemsUserIdShareIdEventStreamThrowableError1 {
            throw error
        }
        closureGetItems()
        return stubbedGetItemsResult
    }
    // MARK: - getItemRevisions
    public var getItemRevisionsUserIdShareIdItemIdLastTokenThrowableError2: Error?
    public var closureGetItemRevisions: () -> () = {}
    public var invokedGetItemRevisionsfunction = false
    public var invokedGetItemRevisionsCount = 0
    public var invokedGetItemRevisionsParameters: (userId: String, shareId: String, itemId: String, lastToken: String?)?
    public var invokedGetItemRevisionsParametersList = [(userId: String, shareId: String, itemId: String, lastToken: String?)]()
    public var stubbedGetItemRevisionsResult: Paginated<Item>!

    public func getItemRevisions(userId: String, shareId: String, itemId: String, lastToken: String?) async throws -> Paginated<Item> {
        invokedGetItemRevisionsfunction = true
        invokedGetItemRevisionsCount += 1
        invokedGetItemRevisionsParameters = (userId, shareId, itemId, lastToken)
        invokedGetItemRevisionsParametersList.append((userId, shareId, itemId, lastToken))
        if let error = getItemRevisionsUserIdShareIdItemIdLastTokenThrowableError2 {
            throw error
        }
        closureGetItemRevisions()
        return stubbedGetItemRevisionsResult
    }
    // MARK: - createItem
    public var createItemUserIdShareIdRequestThrowableError3: Error?
    public var closureCreateItem: () -> () = {}
    public var invokedCreateItemfunction = false
    public var invokedCreateItemCount = 0
    public var invokedCreateItemParameters: (userId: String, shareId: String, request: CreateItemRequest)?
    public var invokedCreateItemParametersList = [(userId: String, shareId: String, request: CreateItemRequest)]()
    public var stubbedCreateItemResult: Item!

    public func createItem(userId: String, shareId: String, request: CreateItemRequest) async throws -> Item {
        invokedCreateItemfunction = true
        invokedCreateItemCount += 1
        invokedCreateItemParameters = (userId, shareId, request)
        invokedCreateItemParametersList.append((userId, shareId, request))
        if let error = createItemUserIdShareIdRequestThrowableError3 {
            throw error
        }
        closureCreateItem()
        return stubbedCreateItemResult
    }
    // MARK: - createAlias
    public var createAliasUserIdShareIdRequestThrowableError4: Error?
    public var closureCreateAlias: () -> () = {}
    public var invokedCreateAliasfunction = false
    public var invokedCreateAliasCount = 0
    public var invokedCreateAliasParameters: (userId: String, shareId: String, request: CreateCustomAliasRequest)?
    public var invokedCreateAliasParametersList = [(userId: String, shareId: String, request: CreateCustomAliasRequest)]()
    public var stubbedCreateAliasResult: Item!

    public func createAlias(userId: String, shareId: String, request: CreateCustomAliasRequest) async throws -> Item {
        invokedCreateAliasfunction = true
        invokedCreateAliasCount += 1
        invokedCreateAliasParameters = (userId, shareId, request)
        invokedCreateAliasParametersList.append((userId, shareId, request))
        if let error = createAliasUserIdShareIdRequestThrowableError4 {
            throw error
        }
        closureCreateAlias()
        return stubbedCreateAliasResult
    }
    // MARK: - createAliasAndAnotherItem
    public var createAliasAndAnotherItemUserIdShareIdRequestThrowableError5: Error?
    public var closureCreateAliasAndAnotherItem: () -> () = {}
    public var invokedCreateAliasAndAnotherItemfunction = false
    public var invokedCreateAliasAndAnotherItemCount = 0
    public var invokedCreateAliasAndAnotherItemParameters: (userId: String, shareId: String, request: CreateAliasAndAnotherItemRequest)?
    public var invokedCreateAliasAndAnotherItemParametersList = [(userId: String, shareId: String, request: CreateAliasAndAnotherItemRequest)]()
    public var stubbedCreateAliasAndAnotherItemResult: CreateAliasAndAnotherItemResponse.Bundle!

    public func createAliasAndAnotherItem(userId: String, shareId: String, request: CreateAliasAndAnotherItemRequest) async throws -> CreateAliasAndAnotherItemResponse.Bundle {
        invokedCreateAliasAndAnotherItemfunction = true
        invokedCreateAliasAndAnotherItemCount += 1
        invokedCreateAliasAndAnotherItemParameters = (userId, shareId, request)
        invokedCreateAliasAndAnotherItemParametersList.append((userId, shareId, request))
        if let error = createAliasAndAnotherItemUserIdShareIdRequestThrowableError5 {
            throw error
        }
        closureCreateAliasAndAnotherItem()
        return stubbedCreateAliasAndAnotherItemResult
    }
    // MARK: - trashItem
    public var trashItemShareIdUserIdThrowableError6: Error?
    public var closureTrashItem: () -> () = {}
    public var invokedTrashItemfunction = false
    public var invokedTrashItemCount = 0
    public var invokedTrashItemParameters: (items: [Item], shareId: String, userId: String)?
    public var invokedTrashItemParametersList = [(items: [Item], shareId: String, userId: String)]()
    public var stubbedTrashItemResult: [ModifiedItem]!

    public func trashItem(_ items: [Item], shareId: String, userId: String) async throws -> [ModifiedItem] {
        invokedTrashItemfunction = true
        invokedTrashItemCount += 1
        invokedTrashItemParameters = (items, shareId, userId)
        invokedTrashItemParametersList.append((items, shareId, userId))
        if let error = trashItemShareIdUserIdThrowableError6 {
            throw error
        }
        closureTrashItem()
        return stubbedTrashItemResult
    }
    // MARK: - untrashItem
    public var untrashItemShareIdUserIdThrowableError7: Error?
    public var closureUntrashItem: () -> () = {}
    public var invokedUntrashItemfunction = false
    public var invokedUntrashItemCount = 0
    public var invokedUntrashItemParameters: (items: [Item], shareId: String, userId: String)?
    public var invokedUntrashItemParametersList = [(items: [Item], shareId: String, userId: String)]()
    public var stubbedUntrashItemResult: [ModifiedItem]!

    public func untrashItem(_ items: [Item], shareId: String, userId: String) async throws -> [ModifiedItem] {
        invokedUntrashItemfunction = true
        invokedUntrashItemCount += 1
        invokedUntrashItemParameters = (items, shareId, userId)
        invokedUntrashItemParametersList.append((items, shareId, userId))
        if let error = untrashItemShareIdUserIdThrowableError7 {
            throw error
        }
        closureUntrashItem()
        return stubbedUntrashItemResult
    }
    // MARK: - deleteItem
    public var deleteItemShareIdSkipTrashUserIdThrowableError8: Error?
    public var closureDeleteItem: () -> () = {}
    public var invokedDeleteItemfunction = false
    public var invokedDeleteItemCount = 0
    public var invokedDeleteItemParameters: (items: [Item], shareId: String, skipTrash: Bool, userId: String)?
    public var invokedDeleteItemParametersList = [(items: [Item], shareId: String, skipTrash: Bool, userId: String)]()

    public func deleteItem(_ items: [Item], shareId: String, skipTrash: Bool, userId: String) async throws {
        invokedDeleteItemfunction = true
        invokedDeleteItemCount += 1
        invokedDeleteItemParameters = (items, shareId, skipTrash, userId)
        invokedDeleteItemParametersList.append((items, shareId, skipTrash, userId))
        if let error = deleteItemShareIdSkipTrashUserIdThrowableError8 {
            throw error
        }
        closureDeleteItem()
    }
    // MARK: - updateItem
    public var updateItemUserIdShareIdItemIdRequestThrowableError9: Error?
    public var closureUpdateItem: () -> () = {}
    public var invokedUpdateItemfunction = false
    public var invokedUpdateItemCount = 0
    public var invokedUpdateItemParameters: (userId: String, shareId: String, itemId: String, request: UpdateItemRequest)?
    public var invokedUpdateItemParametersList = [(userId: String, shareId: String, itemId: String, request: UpdateItemRequest)]()
    public var stubbedUpdateItemResult: Item!

    public func updateItem(userId: String, shareId: String, itemId: String, request: UpdateItemRequest) async throws -> Item {
        invokedUpdateItemfunction = true
        invokedUpdateItemCount += 1
        invokedUpdateItemParameters = (userId, shareId, itemId, request)
        invokedUpdateItemParametersList.append((userId, shareId, itemId, request))
        if let error = updateItemUserIdShareIdItemIdRequestThrowableError9 {
            throw error
        }
        closureUpdateItem()
        return stubbedUpdateItemResult
    }
    // MARK: - updateLastUseTime
    public var updateLastUseTimeUserIdShareIdItemIdLastUseTimeThrowableError10: Error?
    public var closureUpdateLastUseTime: () -> () = {}
    public var invokedUpdateLastUseTimefunction = false
    public var invokedUpdateLastUseTimeCount = 0
    public var invokedUpdateLastUseTimeParameters: (userId: String, shareId: String, itemId: String, lastUseTime: TimeInterval)?
    public var invokedUpdateLastUseTimeParametersList = [(userId: String, shareId: String, itemId: String, lastUseTime: TimeInterval)]()
    public var stubbedUpdateLastUseTimeResult: Item!

    public func updateLastUseTime(userId: String, shareId: String, itemId: String, lastUseTime: TimeInterval) async throws -> Item {
        invokedUpdateLastUseTimefunction = true
        invokedUpdateLastUseTimeCount += 1
        invokedUpdateLastUseTimeParameters = (userId, shareId, itemId, lastUseTime)
        invokedUpdateLastUseTimeParametersList.append((userId, shareId, itemId, lastUseTime))
        if let error = updateLastUseTimeUserIdShareIdItemIdLastUseTimeThrowableError10 {
            throw error
        }
        closureUpdateLastUseTime()
        return stubbedUpdateLastUseTimeResult
    }
    // MARK: - moveUserIdItemIdFromShareIdRequest
    public var moveUserIdItemIdFromShareIdRequestThrowableError11: Error?
    public var closureMoveUserIdItemIdFromShareIdRequestAsync11: () -> () = {}
    public var invokedMoveUserIdItemIdFromShareIdRequestAsync11 = false
    public var invokedMoveUserIdItemIdFromShareIdRequestAsyncCount11 = 0
    public var invokedMoveUserIdItemIdFromShareIdRequestAsyncParameters11: (userId: String, itemId: String, fromShareId: String, request: MoveItemRequest)?
    public var invokedMoveUserIdItemIdFromShareIdRequestAsyncParametersList11 = [(userId: String, itemId: String, fromShareId: String, request: MoveItemRequest)]()
    public var stubbedMoveUserIdItemIdFromShareIdRequestAsyncResult11: Item!

    public func move(userId: String, itemId: String, fromShareId: String, request: MoveItemRequest) async throws -> Item {
        invokedMoveUserIdItemIdFromShareIdRequestAsync11 = true
        invokedMoveUserIdItemIdFromShareIdRequestAsyncCount11 += 1
        invokedMoveUserIdItemIdFromShareIdRequestAsyncParameters11 = (userId, itemId, fromShareId, request)
        invokedMoveUserIdItemIdFromShareIdRequestAsyncParametersList11.append((userId, itemId, fromShareId, request))
        if let error = moveUserIdItemIdFromShareIdRequestThrowableError11 {
            throw error
        }
        closureMoveUserIdItemIdFromShareIdRequestAsync11()
        return stubbedMoveUserIdItemIdFromShareIdRequestAsyncResult11
    }
    // MARK: - moveUserIdFromShareIdRequest
    public var moveUserIdFromShareIdRequestThrowableError12: Error?
    public var closureMoveUserIdFromShareIdRequestAsync12: () -> () = {}
    public var invokedMoveUserIdFromShareIdRequestAsync12 = false
    public var invokedMoveUserIdFromShareIdRequestAsyncCount12 = 0
    public var invokedMoveUserIdFromShareIdRequestAsyncParameters12: (userId: String, fromShareId: String, request: MoveItemsRequest)?
    public var invokedMoveUserIdFromShareIdRequestAsyncParametersList12 = [(userId: String, fromShareId: String, request: MoveItemsRequest)]()
    public var stubbedMoveUserIdFromShareIdRequestAsyncResult12: [Item]!

    public func move(userId: String, fromShareId: String, request: MoveItemsRequest) async throws -> [Item] {
        invokedMoveUserIdFromShareIdRequestAsync12 = true
        invokedMoveUserIdFromShareIdRequestAsyncCount12 += 1
        invokedMoveUserIdFromShareIdRequestAsyncParameters12 = (userId, fromShareId, request)
        invokedMoveUserIdFromShareIdRequestAsyncParametersList12.append((userId, fromShareId, request))
        if let error = moveUserIdFromShareIdRequestThrowableError12 {
            throw error
        }
        closureMoveUserIdFromShareIdRequestAsync12()
        return stubbedMoveUserIdFromShareIdRequestAsyncResult12
    }
    // MARK: - pin
    public var pinUserIdItemThrowableError13: Error?
    public var closurePin: () -> () = {}
    public var invokedPinfunction = false
    public var invokedPinCount = 0
    public var invokedPinParameters: (userId: String, item: any ItemIdentifiable)?
    public var invokedPinParametersList = [(userId: String, item: any ItemIdentifiable)]()
    public var stubbedPinResult: Item!

    public func pin(userId: String, item: any ItemIdentifiable) async throws -> Item {
        invokedPinfunction = true
        invokedPinCount += 1
        invokedPinParameters = (userId, item)
        invokedPinParametersList.append((userId, item))
        if let error = pinUserIdItemThrowableError13 {
            throw error
        }
        closurePin()
        return stubbedPinResult
    }
    // MARK: - unpin
    public var unpinUserIdItemThrowableError14: Error?
    public var closureUnpin: () -> () = {}
    public var invokedUnpinfunction = false
    public var invokedUnpinCount = 0
    public var invokedUnpinParameters: (userId: String, item: any ItemIdentifiable)?
    public var invokedUnpinParametersList = [(userId: String, item: any ItemIdentifiable)]()
    public var stubbedUnpinResult: Item!

    public func unpin(userId: String, item: any ItemIdentifiable) async throws -> Item {
        invokedUnpinfunction = true
        invokedUnpinCount += 1
        invokedUnpinParameters = (userId, item)
        invokedUnpinParametersList.append((userId, item))
        if let error = unpinUserIdItemThrowableError14 {
            throw error
        }
        closureUnpin()
        return stubbedUnpinResult
    }
    // MARK: - updateItemFlags
    public var updateItemFlagsUserIdItemIdShareIdRequestThrowableError15: Error?
    public var closureUpdateItemFlags: () -> () = {}
    public var invokedUpdateItemFlagsfunction = false
    public var invokedUpdateItemFlagsCount = 0
    public var invokedUpdateItemFlagsParameters: (userId: String, itemId: String, shareId: String, request: UpdateItemFlagsRequest)?
    public var invokedUpdateItemFlagsParametersList = [(userId: String, itemId: String, shareId: String, request: UpdateItemFlagsRequest)]()
    public var stubbedUpdateItemFlagsResult: Item!

    public func updateItemFlags(userId: String, itemId: String, shareId: String, request: UpdateItemFlagsRequest) async throws -> Item {
        invokedUpdateItemFlagsfunction = true
        invokedUpdateItemFlagsCount += 1
        invokedUpdateItemFlagsParameters = (userId, itemId, shareId, request)
        invokedUpdateItemFlagsParametersList.append((userId, itemId, shareId, request))
        if let error = updateItemFlagsUserIdItemIdShareIdRequestThrowableError15 {
            throw error
        }
        closureUpdateItemFlags()
        return stubbedUpdateItemFlagsResult
    }
    // MARK: - createPendingAliasesItem
    public var createPendingAliasesItemUserIdShareIdRequestThrowableError16: Error?
    public var closureCreatePendingAliasesItem: () -> () = {}
    public var invokedCreatePendingAliasesItemfunction = false
    public var invokedCreatePendingAliasesItemCount = 0
    public var invokedCreatePendingAliasesItemParameters: (userId: String, shareId: String, request: CreateAliasesFromPendingRequest)?
    public var invokedCreatePendingAliasesItemParametersList = [(userId: String, shareId: String, request: CreateAliasesFromPendingRequest)]()
    public var stubbedCreatePendingAliasesItemResult: [Item]!

    public func createPendingAliasesItem(userId: String, shareId: String, request: CreateAliasesFromPendingRequest) async throws -> [Item] {
        invokedCreatePendingAliasesItemfunction = true
        invokedCreatePendingAliasesItemCount += 1
        invokedCreatePendingAliasesItemParameters = (userId, shareId, request)
        invokedCreatePendingAliasesItemParametersList.append((userId, shareId, request))
        if let error = createPendingAliasesItemUserIdShareIdRequestThrowableError16 {
            throw error
        }
        closureCreatePendingAliasesItem()
        return stubbedCreatePendingAliasesItemResult
    }
    // MARK: - toggleAliasStatus
    public var toggleAliasStatusUserIdShareIdItemIdEnableThrowableError17: Error?
    public var closureToggleAliasStatus: () -> () = {}
    public var invokedToggleAliasStatusfunction = false
    public var invokedToggleAliasStatusCount = 0
    public var invokedToggleAliasStatusParameters: (userId: String, shareId: String, itemId: String, enable: Bool)?
    public var invokedToggleAliasStatusParametersList = [(userId: String, shareId: String, itemId: String, enable: Bool)]()
    public var stubbedToggleAliasStatusResult: Item!

    public func toggleAliasStatus(userId: String, shareId: String, itemId: String, enable: Bool) async throws -> Item {
        invokedToggleAliasStatusfunction = true
        invokedToggleAliasStatusCount += 1
        invokedToggleAliasStatusParameters = (userId, shareId, itemId, enable)
        invokedToggleAliasStatusParametersList.append((userId, shareId, itemId, enable))
        if let error = toggleAliasStatusUserIdShareIdItemIdEnableThrowableError17 {
            throw error
        }
        closureToggleAliasStatus()
        return stubbedToggleAliasStatusResult
    }
}
