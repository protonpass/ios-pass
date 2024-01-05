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
import Entities
import Foundation

public final class RemoteItemDatasourceProtocolMock: @unchecked Sendable, RemoteItemDatasourceProtocol {

    public init() {}

    // MARK: - getItemRevisionsShareIdEventStream
    public var getItemRevisionsShareIdEventStreamThrowableError1: Error?
    public var closureGetItemRevisionsShareIdEventStreamAsync1: () -> () = {}
    public var invokedGetItemRevisionsShareIdEventStreamAsync1 = false
    public var invokedGetItemRevisionsShareIdEventStreamAsyncCount1 = 0
    public var invokedGetItemRevisionsShareIdEventStreamAsyncParameters1: (shareId: String, eventStream: VaultSyncEventStream?)?
    public var invokedGetItemRevisionsShareIdEventStreamAsyncParametersList1 = [(shareId: String, eventStream: VaultSyncEventStream?)]()
    public var stubbedGetItemRevisionsShareIdEventStreamAsyncResult1: [ItemRevision]!

    public func getItemRevisions(shareId: String, eventStream: VaultSyncEventStream?) async throws -> [ItemRevision] {
        invokedGetItemRevisionsShareIdEventStreamAsync1 = true
        invokedGetItemRevisionsShareIdEventStreamAsyncCount1 += 1
        invokedGetItemRevisionsShareIdEventStreamAsyncParameters1 = (shareId, eventStream)
        invokedGetItemRevisionsShareIdEventStreamAsyncParametersList1.append((shareId, eventStream))
        if let error = getItemRevisionsShareIdEventStreamThrowableError1 {
            throw error
        }
        closureGetItemRevisionsShareIdEventStreamAsync1()
        return stubbedGetItemRevisionsShareIdEventStreamAsyncResult1
    }
    // MARK: - getItemRevisionsShareIdItemId
    public var getItemRevisionsShareIdItemIdThrowableError2: Error?
    public var closureGetItemRevisionsShareIdItemIdAsync2: () -> () = {}
    public var invokedGetItemRevisionsShareIdItemIdAsync2 = false
    public var invokedGetItemRevisionsShareIdItemIdAsyncCount2 = 0
    public var invokedGetItemRevisionsShareIdItemIdAsyncParameters2: (shareId: String, itemId: String)?
    public var invokedGetItemRevisionsShareIdItemIdAsyncParametersList2 = [(shareId: String, itemId: String)]()
    public var stubbedGetItemRevisionsShareIdItemIdAsyncResult2: [ItemRevision]!

    public func getItemRevisions(shareId: String, itemId: String) async throws -> [ItemRevision] {
        invokedGetItemRevisionsShareIdItemIdAsync2 = true
        invokedGetItemRevisionsShareIdItemIdAsyncCount2 += 1
        invokedGetItemRevisionsShareIdItemIdAsyncParameters2 = (shareId, itemId)
        invokedGetItemRevisionsShareIdItemIdAsyncParametersList2.append((shareId, itemId))
        if let error = getItemRevisionsShareIdItemIdThrowableError2 {
            throw error
        }
        closureGetItemRevisionsShareIdItemIdAsync2()
        return stubbedGetItemRevisionsShareIdItemIdAsyncResult2
    }
    // MARK: - createItem
    public var createItemShareIdRequestThrowableError3: Error?
    public var closureCreateItem: () -> () = {}
    public var invokedCreateItemfunction = false
    public var invokedCreateItemCount = 0
    public var invokedCreateItemParameters: (shareId: String, request: CreateItemRequest)?
    public var invokedCreateItemParametersList = [(shareId: String, request: CreateItemRequest)]()
    public var stubbedCreateItemResult: ItemRevision!

    public func createItem(shareId: String, request: CreateItemRequest) async throws -> ItemRevision {
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
    public var stubbedCreateAliasResult: ItemRevision!

    public func createAlias(shareId: String, request: CreateCustomAliasRequest) async throws -> ItemRevision {
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
    // MARK: - trashItemRevisions
    public var trashItemRevisionsShareIdThrowableError6: Error?
    public var closureTrashItemRevisions: () -> () = {}
    public var invokedTrashItemRevisionsfunction = false
    public var invokedTrashItemRevisionsCount = 0
    public var invokedTrashItemRevisionsParameters: (items: [ItemRevision], shareId: String)?
    public var invokedTrashItemRevisionsParametersList = [(items: [ItemRevision], shareId: String)]()
    public var stubbedTrashItemRevisionsResult: [ModifiedItem]!

    public func trashItemRevisions(_ items: [ItemRevision], shareId: String) async throws -> [ModifiedItem] {
        invokedTrashItemRevisionsfunction = true
        invokedTrashItemRevisionsCount += 1
        invokedTrashItemRevisionsParameters = (items, shareId)
        invokedTrashItemRevisionsParametersList.append((items, shareId))
        if let error = trashItemRevisionsShareIdThrowableError6 {
            throw error
        }
        closureTrashItemRevisions()
        return stubbedTrashItemRevisionsResult
    }
    // MARK: - untrashItemRevisions
    public var untrashItemRevisionsShareIdThrowableError7: Error?
    public var closureUntrashItemRevisions: () -> () = {}
    public var invokedUntrashItemRevisionsfunction = false
    public var invokedUntrashItemRevisionsCount = 0
    public var invokedUntrashItemRevisionsParameters: (items: [ItemRevision], shareId: String)?
    public var invokedUntrashItemRevisionsParametersList = [(items: [ItemRevision], shareId: String)]()
    public var stubbedUntrashItemRevisionsResult: [ModifiedItem]!

    public func untrashItemRevisions(_ items: [ItemRevision], shareId: String) async throws -> [ModifiedItem] {
        invokedUntrashItemRevisionsfunction = true
        invokedUntrashItemRevisionsCount += 1
        invokedUntrashItemRevisionsParameters = (items, shareId)
        invokedUntrashItemRevisionsParametersList.append((items, shareId))
        if let error = untrashItemRevisionsShareIdThrowableError7 {
            throw error
        }
        closureUntrashItemRevisions()
        return stubbedUntrashItemRevisionsResult
    }
    // MARK: - deleteItemRevisions
    public var deleteItemRevisionsShareIdSkipTrashThrowableError8: Error?
    public var closureDeleteItemRevisions: () -> () = {}
    public var invokedDeleteItemRevisionsfunction = false
    public var invokedDeleteItemRevisionsCount = 0
    public var invokedDeleteItemRevisionsParameters: (items: [ItemRevision], shareId: String, skipTrash: Bool)?
    public var invokedDeleteItemRevisionsParametersList = [(items: [ItemRevision], shareId: String, skipTrash: Bool)]()

    public func deleteItemRevisions(_ items: [ItemRevision], shareId: String, skipTrash: Bool) async throws {
        invokedDeleteItemRevisionsfunction = true
        invokedDeleteItemRevisionsCount += 1
        invokedDeleteItemRevisionsParameters = (items, shareId, skipTrash)
        invokedDeleteItemRevisionsParametersList.append((items, shareId, skipTrash))
        if let error = deleteItemRevisionsShareIdSkipTrashThrowableError8 {
            throw error
        }
        closureDeleteItemRevisions()
    }
    // MARK: - updateItem
    public var updateItemShareIdItemIdRequestThrowableError9: Error?
    public var closureUpdateItem: () -> () = {}
    public var invokedUpdateItemfunction = false
    public var invokedUpdateItemCount = 0
    public var invokedUpdateItemParameters: (shareId: String, itemId: String, request: UpdateItemRequest)?
    public var invokedUpdateItemParametersList = [(shareId: String, itemId: String, request: UpdateItemRequest)]()
    public var stubbedUpdateItemResult: ItemRevision!

    public func updateItem(shareId: String, itemId: String, request: UpdateItemRequest) async throws -> ItemRevision {
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
    public var stubbedUpdateLastUseTimeResult: ItemRevision!

    public func updateLastUseTime(shareId: String, itemId: String, lastUseTime: TimeInterval) async throws -> ItemRevision {
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
    public var stubbedMoveItemIdFromShareIdRequestAsyncResult11: ItemRevision!

    public func move(itemId: String, fromShareId: String, request: MoveItemRequest) async throws -> ItemRevision {
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
    public var stubbedMoveFromShareIdRequestAsyncResult12: [ItemRevision]!

    public func move(fromShareId: String, request: MoveItemsRequest) async throws -> [ItemRevision] {
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
    public var stubbedPinResult: ItemRevision!

    public func pin(item: any ItemIdentifiable) async throws -> ItemRevision {
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
    public var stubbedUnpinResult: ItemRevision!

    public func unpin(item: any ItemIdentifiable) async throws -> ItemRevision {
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
