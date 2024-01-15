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
import Core
import Entities
import Foundation

public final class RemoteItemDatasourceProtocolMock: @unchecked Sendable, RemoteItemDatasourceProtocol {

    public init() {}

    // MARK: - getItems
    public var getItemsShareIdEventStreamThrowableError1: Error?
    public var closureGetItems: () -> () = {}
    public var invokedGetItemsfunction = false
    public var invokedGetItemsCount = 0
    public var invokedGetItemsParameters: (shareId: String, eventStream: VaultSyncEventStream?)?
    public var invokedGetItemsParametersList = [(shareId: String, eventStream: VaultSyncEventStream?)]()
    public var stubbedGetItemsResult: [Item]!

    public func getItems(shareId: String, eventStream: VaultSyncEventStream?) async throws -> [Item] {
        invokedGetItemsfunction = true
        invokedGetItemsCount += 1
        invokedGetItemsParameters = (shareId, eventStream)
        invokedGetItemsParametersList.append((shareId, eventStream))
        if let error = getItemsShareIdEventStreamThrowableError1 {
            throw error
        }
        closureGetItems()
        return stubbedGetItemsResult
    }
    // MARK: - getItemRevisions
    public var getItemRevisionsShareIdItemIdLastTokenThrowableError2: Error?
    public var closureGetItemRevisions: () -> () = {}
    public var invokedGetItemRevisionsfunction = false
    public var invokedGetItemRevisionsCount = 0
    public var invokedGetItemRevisionsParameters: (shareId: String, itemId: String, lastToken: String?)?
    public var invokedGetItemRevisionsParametersList = [(shareId: String, itemId: String, lastToken: String?)]()
    public var stubbedGetItemRevisionsResult: Paginated<Item>!

    public func getItemRevisions(shareId: String, itemId: String, lastToken: String?) async throws -> Paginated<Item> {
        invokedGetItemRevisionsfunction = true
        invokedGetItemRevisionsCount += 1
        invokedGetItemRevisionsParameters = (shareId, itemId, lastToken)
        invokedGetItemRevisionsParametersList.append((shareId, itemId, lastToken))
        if let error = getItemRevisionsShareIdItemIdLastTokenThrowableError2 {
            throw error
        }
        closureGetItemRevisions()
        return stubbedGetItemRevisionsResult
    }
    // MARK: - createItem
    public var createItemShareIdRequestThrowableError3: Error?
    public var closureCreateItem: () -> () = {}
    public var invokedCreateItemfunction = false
    public var invokedCreateItemCount = 0
    public var invokedCreateItemParameters: (shareId: String, request: CreateItemRequest)?
    public var invokedCreateItemParametersList = [(shareId: String, request: CreateItemRequest)]()
    public var stubbedCreateItemResult: Item!

    public func createItem(shareId: String, request: CreateItemRequest) async throws -> Item {
        invokedCreateItemfunction = true
        invokedCreateItemCount += 1
        invokedCreateItemParameters = (shareId, request)
        invokedCreateItemParametersList.append((shareId, request))
        if let error = createItemShareIdRequestThrowableError3 {
            throw error
        }
        closureCreateItem()
        return stubbedCreateItemResult
    }
    // MARK: - createAlias
    public var createAliasShareIdRequestThrowableError4: Error?
    public var closureCreateAlias: () -> () = {}
    public var invokedCreateAliasfunction = false
    public var invokedCreateAliasCount = 0
    public var invokedCreateAliasParameters: (shareId: String, request: CreateCustomAliasRequest)?
    public var invokedCreateAliasParametersList = [(shareId: String, request: CreateCustomAliasRequest)]()
    public var stubbedCreateAliasResult: Item!

    public func createAlias(shareId: String, request: CreateCustomAliasRequest) async throws -> Item {
        invokedCreateAliasfunction = true
        invokedCreateAliasCount += 1
        invokedCreateAliasParameters = (shareId, request)
        invokedCreateAliasParametersList.append((shareId, request))
        if let error = createAliasShareIdRequestThrowableError4 {
            throw error
        }
        closureCreateAlias()
        return stubbedCreateAliasResult
    }
    // MARK: - createAliasAndAnotherItem
    public var createAliasAndAnotherItemShareIdRequestThrowableError5: Error?
    public var closureCreateAliasAndAnotherItem: () -> () = {}
    public var invokedCreateAliasAndAnotherItemfunction = false
    public var invokedCreateAliasAndAnotherItemCount = 0
    public var invokedCreateAliasAndAnotherItemParameters: (shareId: String, request: CreateAliasAndAnotherItemRequest)?
    public var invokedCreateAliasAndAnotherItemParametersList = [(shareId: String, request: CreateAliasAndAnotherItemRequest)]()
    public var stubbedCreateAliasAndAnotherItemResult: CreateAliasAndAnotherItemResponse.Bundle!

    public func createAliasAndAnotherItem(shareId: String, request: CreateAliasAndAnotherItemRequest) async throws -> CreateAliasAndAnotherItemResponse.Bundle {
        invokedCreateAliasAndAnotherItemfunction = true
        invokedCreateAliasAndAnotherItemCount += 1
        invokedCreateAliasAndAnotherItemParameters = (shareId, request)
        invokedCreateAliasAndAnotherItemParametersList.append((shareId, request))
        if let error = createAliasAndAnotherItemShareIdRequestThrowableError5 {
            throw error
        }
        closureCreateAliasAndAnotherItem()
        return stubbedCreateAliasAndAnotherItemResult
    }
    // MARK: - trashItem
    public var trashItemShareIdThrowableError6: Error?
    public var closureTrashItem: () -> () = {}
    public var invokedTrashItemfunction = false
    public var invokedTrashItemCount = 0
    public var invokedTrashItemParameters: (items: [Item], shareId: String)?
    public var invokedTrashItemParametersList = [(items: [Item], shareId: String)]()
    public var stubbedTrashItemResult: [ModifiedItem]!

    public func trashItem(_ items: [Item], shareId: String) async throws -> [ModifiedItem] {
        invokedTrashItemfunction = true
        invokedTrashItemCount += 1
        invokedTrashItemParameters = (items, shareId)
        invokedTrashItemParametersList.append((items, shareId))
        if let error = trashItemShareIdThrowableError6 {
            throw error
        }
        closureTrashItem()
        return stubbedTrashItemResult
    }
    // MARK: - untrashItem
    public var untrashItemShareIdThrowableError7: Error?
    public var closureUntrashItem: () -> () = {}
    public var invokedUntrashItemfunction = false
    public var invokedUntrashItemCount = 0
    public var invokedUntrashItemParameters: (items: [Item], shareId: String)?
    public var invokedUntrashItemParametersList = [(items: [Item], shareId: String)]()
    public var stubbedUntrashItemResult: [ModifiedItem]!

    public func untrashItem(_ items: [Item], shareId: String) async throws -> [ModifiedItem] {
        invokedUntrashItemfunction = true
        invokedUntrashItemCount += 1
        invokedUntrashItemParameters = (items, shareId)
        invokedUntrashItemParametersList.append((items, shareId))
        if let error = untrashItemShareIdThrowableError7 {
            throw error
        }
        closureUntrashItem()
        return stubbedUntrashItemResult
    }
    // MARK: - deleteItem
    public var deleteItemShareIdSkipTrashThrowableError8: Error?
    public var closureDeleteItem: () -> () = {}
    public var invokedDeleteItemfunction = false
    public var invokedDeleteItemCount = 0
    public var invokedDeleteItemParameters: (items: [Item], shareId: String, skipTrash: Bool)?
    public var invokedDeleteItemParametersList = [(items: [Item], shareId: String, skipTrash: Bool)]()

    public func deleteItem(_ items: [Item], shareId: String, skipTrash: Bool) async throws {
        invokedDeleteItemfunction = true
        invokedDeleteItemCount += 1
        invokedDeleteItemParameters = (items, shareId, skipTrash)
        invokedDeleteItemParametersList.append((items, shareId, skipTrash))
        if let error = deleteItemShareIdSkipTrashThrowableError8 {
            throw error
        }
        closureDeleteItem()
    }
    // MARK: - updateItem
    public var updateItemShareIdItemIdRequestThrowableError9: Error?
    public var closureUpdateItem: () -> () = {}
    public var invokedUpdateItemfunction = false
    public var invokedUpdateItemCount = 0
    public var invokedUpdateItemParameters: (shareId: String, itemId: String, request: UpdateItemRequest)?
    public var invokedUpdateItemParametersList = [(shareId: String, itemId: String, request: UpdateItemRequest)]()
    public var stubbedUpdateItemResult: Item!

    public func updateItem(shareId: String, itemId: String, request: UpdateItemRequest) async throws -> Item {
        invokedUpdateItemfunction = true
        invokedUpdateItemCount += 1
        invokedUpdateItemParameters = (shareId, itemId, request)
        invokedUpdateItemParametersList.append((shareId, itemId, request))
        if let error = updateItemShareIdItemIdRequestThrowableError9 {
            throw error
        }
        closureUpdateItem()
        return stubbedUpdateItemResult
    }
    // MARK: - updateLastUseTime
    public var updateLastUseTimeShareIdItemIdLastUseTimeThrowableError10: Error?
    public var closureUpdateLastUseTime: () -> () = {}
    public var invokedUpdateLastUseTimefunction = false
    public var invokedUpdateLastUseTimeCount = 0
    public var invokedUpdateLastUseTimeParameters: (shareId: String, itemId: String, lastUseTime: TimeInterval)?
    public var invokedUpdateLastUseTimeParametersList = [(shareId: String, itemId: String, lastUseTime: TimeInterval)]()
    public var stubbedUpdateLastUseTimeResult: Item!

    public func updateLastUseTime(shareId: String, itemId: String, lastUseTime: TimeInterval) async throws -> Item {
        invokedUpdateLastUseTimefunction = true
        invokedUpdateLastUseTimeCount += 1
        invokedUpdateLastUseTimeParameters = (shareId, itemId, lastUseTime)
        invokedUpdateLastUseTimeParametersList.append((shareId, itemId, lastUseTime))
        if let error = updateLastUseTimeShareIdItemIdLastUseTimeThrowableError10 {
            throw error
        }
        closureUpdateLastUseTime()
        return stubbedUpdateLastUseTimeResult
    }
    // MARK: - moveItemIdFromShareIdRequest
    public var moveItemIdFromShareIdRequestThrowableError11: Error?
    public var closureMoveItemIdFromShareIdRequestAsync11: () -> () = {}
    public var invokedMoveItemIdFromShareIdRequestAsync11 = false
    public var invokedMoveItemIdFromShareIdRequestAsyncCount11 = 0
    public var invokedMoveItemIdFromShareIdRequestAsyncParameters11: (itemId: String, fromShareId: String, request: MoveItemRequest)?
    public var invokedMoveItemIdFromShareIdRequestAsyncParametersList11 = [(itemId: String, fromShareId: String, request: MoveItemRequest)]()
    public var stubbedMoveItemIdFromShareIdRequestAsyncResult11: Item!

    public func move(itemId: String, fromShareId: String, request: MoveItemRequest) async throws -> Item {
        invokedMoveItemIdFromShareIdRequestAsync11 = true
        invokedMoveItemIdFromShareIdRequestAsyncCount11 += 1
        invokedMoveItemIdFromShareIdRequestAsyncParameters11 = (itemId, fromShareId, request)
        invokedMoveItemIdFromShareIdRequestAsyncParametersList11.append((itemId, fromShareId, request))
        if let error = moveItemIdFromShareIdRequestThrowableError11 {
            throw error
        }
        closureMoveItemIdFromShareIdRequestAsync11()
        return stubbedMoveItemIdFromShareIdRequestAsyncResult11
    }
    // MARK: - moveFromShareIdRequest
    public var moveFromShareIdRequestThrowableError12: Error?
    public var closureMoveFromShareIdRequestAsync12: () -> () = {}
    public var invokedMoveFromShareIdRequestAsync12 = false
    public var invokedMoveFromShareIdRequestAsyncCount12 = 0
    public var invokedMoveFromShareIdRequestAsyncParameters12: (fromShareId: String, request: MoveItemsRequest)?
    public var invokedMoveFromShareIdRequestAsyncParametersList12 = [(fromShareId: String, request: MoveItemsRequest)]()
    public var stubbedMoveFromShareIdRequestAsyncResult12: [Item]!

    public func move(fromShareId: String, request: MoveItemsRequest) async throws -> [Item] {
        invokedMoveFromShareIdRequestAsync12 = true
        invokedMoveFromShareIdRequestAsyncCount12 += 1
        invokedMoveFromShareIdRequestAsyncParameters12 = (fromShareId, request)
        invokedMoveFromShareIdRequestAsyncParametersList12.append((fromShareId, request))
        if let error = moveFromShareIdRequestThrowableError12 {
            throw error
        }
        closureMoveFromShareIdRequestAsync12()
        return stubbedMoveFromShareIdRequestAsyncResult12
    }
    // MARK: - pin
    public var pinItemThrowableError13: Error?
    public var closurePin: () -> () = {}
    public var invokedPinfunction = false
    public var invokedPinCount = 0
    public var invokedPinParameters: (item: any ItemIdentifiable, Void)?
    public var invokedPinParametersList = [(item: any ItemIdentifiable, Void)]()
    public var stubbedPinResult: Item!

    public func pin(item: any ItemIdentifiable) async throws -> Item {
        invokedPinfunction = true
        invokedPinCount += 1
        invokedPinParameters = (item, ())
        invokedPinParametersList.append((item, ()))
        if let error = pinItemThrowableError13 {
            throw error
        }
        closurePin()
        return stubbedPinResult
    }
    // MARK: - unpin
    public var unpinItemThrowableError14: Error?
    public var closureUnpin: () -> () = {}
    public var invokedUnpinfunction = false
    public var invokedUnpinCount = 0
    public var invokedUnpinParameters: (item: any ItemIdentifiable, Void)?
    public var invokedUnpinParametersList = [(item: any ItemIdentifiable, Void)]()
    public var stubbedUnpinResult: Item!

    public func unpin(item: any ItemIdentifiable) async throws -> Item {
        invokedUnpinfunction = true
        invokedUnpinCount += 1
        invokedUnpinParameters = (item, ())
        invokedUnpinParametersList.append((item, ()))
        if let error = unpinItemThrowableError14 {
            throw error
        }
        closureUnpin()
        return stubbedUnpinResult
    }
}
