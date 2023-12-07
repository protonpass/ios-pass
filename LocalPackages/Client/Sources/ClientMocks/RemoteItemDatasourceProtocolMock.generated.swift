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
import Entities
import Foundation

public final class RemoteItemDatasourceProtocolMock: @unchecked Sendable, RemoteItemDatasourceProtocol {

    public init() {}

    // MARK: - getItemRevisions
    public var getItemRevisionsShareIdEventStreamThrowableError1: Error?
    public var closureGetItemRevisions: () -> () = {}
    public var invokedGetItemRevisionsfunction = false
    public var invokedGetItemRevisionsCount = 0
    public var invokedGetItemRevisionsParameters: (shareId: String, eventStream: VaultSyncEventStream?)?
    public var invokedGetItemRevisionsParametersList = [(shareId: String, eventStream: VaultSyncEventStream?)]()
    public var stubbedGetItemRevisionsResult: [ItemRevision]!

    public func getItemRevisions(shareId: String, eventStream: VaultSyncEventStream?) async throws -> [ItemRevision] {
        invokedGetItemRevisionsfunction = true
        invokedGetItemRevisionsCount += 1
        invokedGetItemRevisionsParameters = (shareId, eventStream)
        invokedGetItemRevisionsParametersList.append((shareId, eventStream))
        if let error = getItemRevisionsShareIdEventStreamThrowableError1 {
            throw error
        }
        closureGetItemRevisions()
        return stubbedGetItemRevisionsResult
    }
    // MARK: - createItem
    public var createItemShareIdRequestThrowableError2: Error?
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
        if let error = createItemShareIdRequestThrowableError2 {
            throw error
        }
        closureCreateItem()
        return stubbedCreateItemResult
    }
    // MARK: - createAlias
    public var createAliasShareIdRequestThrowableError3: Error?
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
        if let error = createAliasShareIdRequestThrowableError3 {
            throw error
        }
        closureCreateAlias()
        return stubbedCreateAliasResult
    }
    // MARK: - createAliasAndAnotherItem
    public var createAliasAndAnotherItemShareIdRequestThrowableError4: Error?
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
        if let error = createAliasAndAnotherItemShareIdRequestThrowableError4 {
            throw error
        }
        closureCreateAliasAndAnotherItem()
        return stubbedCreateAliasAndAnotherItemResult
    }
    // MARK: - trashItemRevisions
    public var trashItemRevisionsShareIdThrowableError5: Error?
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
        if let error = trashItemRevisionsShareIdThrowableError5 {
            throw error
        }
        closureTrashItemRevisions()
        return stubbedTrashItemRevisionsResult
    }
    // MARK: - untrashItemRevisions
    public var untrashItemRevisionsShareIdThrowableError6: Error?
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
        if let error = untrashItemRevisionsShareIdThrowableError6 {
            throw error
        }
        closureUntrashItemRevisions()
        return stubbedUntrashItemRevisionsResult
    }
    // MARK: - deleteItemRevisions
    public var deleteItemRevisionsShareIdSkipTrashThrowableError7: Error?
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
        if let error = deleteItemRevisionsShareIdSkipTrashThrowableError7 {
            throw error
        }
        closureDeleteItemRevisions()
    }
    // MARK: - updateItem
    public var updateItemShareIdItemIdRequestThrowableError8: Error?
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
        if let error = updateItemShareIdItemIdRequestThrowableError8 {
            throw error
        }
        closureUpdateItem()
        return stubbedUpdateItemResult
    }
    // MARK: - updateLastUseTime
    public var updateLastUseTimeShareIdItemIdLastUseTimeThrowableError9: Error?
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
        if let error = updateLastUseTimeShareIdItemIdLastUseTimeThrowableError9 {
            throw error
        }
        closureUpdateLastUseTime()
        return stubbedUpdateLastUseTimeResult
    }
    // MARK: - moveItemIdFromShareIdRequest
    public var moveItemIdFromShareIdRequestThrowableError10: Error?
    public var closureMoveItemIdFromShareIdRequestAsync10: () -> () = {}
    public var invokedMoveItemIdFromShareIdRequestAsync10 = false
    public var invokedMoveItemIdFromShareIdRequestAsyncCount10 = 0
    public var invokedMoveItemIdFromShareIdRequestAsyncParameters10: (itemId: String, fromShareId: String, request: MoveItemRequest)?
    public var invokedMoveItemIdFromShareIdRequestAsyncParametersList10 = [(itemId: String, fromShareId: String, request: MoveItemRequest)]()
    public var stubbedMoveItemIdFromShareIdRequestAsyncResult10: ItemRevision!

    public func move(itemId: String, fromShareId: String, request: MoveItemRequest) async throws -> ItemRevision {
        invokedMoveItemIdFromShareIdRequestAsync10 = true
        invokedMoveItemIdFromShareIdRequestAsyncCount10 += 1
        invokedMoveItemIdFromShareIdRequestAsyncParameters10 = (itemId, fromShareId, request)
        invokedMoveItemIdFromShareIdRequestAsyncParametersList10.append((itemId, fromShareId, request))
        if let error = moveItemIdFromShareIdRequestThrowableError10 {
            throw error
        }
        closureMoveItemIdFromShareIdRequestAsync10()
        return stubbedMoveItemIdFromShareIdRequestAsyncResult10
    }
    // MARK: - moveFromShareIdRequest
    public var moveFromShareIdRequestThrowableError11: Error?
    public var closureMoveFromShareIdRequestAsync11: () -> () = {}
    public var invokedMoveFromShareIdRequestAsync11 = false
    public var invokedMoveFromShareIdRequestAsyncCount11 = 0
    public var invokedMoveFromShareIdRequestAsyncParameters11: (fromShareId: String, request: MoveItemsRequest)?
    public var invokedMoveFromShareIdRequestAsyncParametersList11 = [(fromShareId: String, request: MoveItemsRequest)]()
    public var stubbedMoveFromShareIdRequestAsyncResult11: [ItemRevision]!

    public func move(fromShareId: String, request: MoveItemsRequest) async throws -> [ItemRevision] {
        invokedMoveFromShareIdRequestAsync11 = true
        invokedMoveFromShareIdRequestAsyncCount11 += 1
        invokedMoveFromShareIdRequestAsyncParameters11 = (fromShareId, request)
        invokedMoveFromShareIdRequestAsyncParametersList11.append((fromShareId, request))
        if let error = moveFromShareIdRequestThrowableError11 {
            throw error
        }
        closureMoveFromShareIdRequestAsync11()
        return stubbedMoveFromShareIdRequestAsyncResult11
    }
    // MARK: - pin
    public var pinItemThrowableError12: Error?
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
        if let error = pinItemThrowableError12 {
            throw error
        }
        closurePin()
        return stubbedPinResult
    }
    // MARK: - unpin
    public var unpinItemThrowableError13: Error?
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
        if let error = unpinItemThrowableError13 {
            throw error
        }
        closureUnpin()
        return stubbedUnpinResult
    }
}
