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
import Entities
import Foundation

final class RemoteItemDatasourceProtocolMock: @unchecked Sendable, RemoteItemDatasourceProtocol {
    // MARK: - getItemRevisions
    var getItemRevisionsShareIdEventStreamThrowableError: Error?
    var closureGetItemRevisions: () -> () = {}
    var invokedGetItemRevisions = false
    var invokedGetItemRevisionsCount = 0
    var invokedGetItemRevisionsParameters: (shareId: String, eventStream: VaultSyncEventStream?)?
    var invokedGetItemRevisionsParametersList = [(shareId: String, eventStream: VaultSyncEventStream?)]()
    var stubbedGetItemRevisionsResult: [ItemRevision]!

    func getItemRevisions(shareId: String, eventStream: VaultSyncEventStream?) async throws -> [ItemRevision] {
        invokedGetItemRevisions = true
        invokedGetItemRevisionsCount += 1
        invokedGetItemRevisionsParameters = (shareId, eventStream)
        invokedGetItemRevisionsParametersList.append((shareId, eventStream))
        if let error = getItemRevisionsShareIdEventStreamThrowableError {
            throw error
        }
        closureGetItemRevisions()
        return stubbedGetItemRevisionsResult
    }
    // MARK: - createItem
    var createItemShareIdRequestThrowableError: Error?
    var closureCreateItem: () -> () = {}
    var invokedCreateItem = false
    var invokedCreateItemCount = 0
    var invokedCreateItemParameters: (shareId: String, request: CreateItemRequest)?
    var invokedCreateItemParametersList = [(shareId: String, request: CreateItemRequest)]()
    var stubbedCreateItemResult: ItemRevision!

    func createItem(shareId: String, request: CreateItemRequest) async throws -> ItemRevision {
        invokedCreateItem = true
        invokedCreateItemCount += 1
        invokedCreateItemParameters = (shareId, request)
        invokedCreateItemParametersList.append((shareId, request))
        if let error = createItemShareIdRequestThrowableError {
            throw error
        }
        closureCreateItem()
        return stubbedCreateItemResult
    }
    // MARK: - createAlias
    var createAliasShareIdRequestThrowableError: Error?
    var closureCreateAlias: () -> () = {}
    var invokedCreateAlias = false
    var invokedCreateAliasCount = 0
    var invokedCreateAliasParameters: (shareId: String, request: CreateCustomAliasRequest)?
    var invokedCreateAliasParametersList = [(shareId: String, request: CreateCustomAliasRequest)]()
    var stubbedCreateAliasResult: ItemRevision!

    func createAlias(shareId: String, request: CreateCustomAliasRequest) async throws -> ItemRevision {
        invokedCreateAlias = true
        invokedCreateAliasCount += 1
        invokedCreateAliasParameters = (shareId, request)
        invokedCreateAliasParametersList.append((shareId, request))
        if let error = createAliasShareIdRequestThrowableError {
            throw error
        }
        closureCreateAlias()
        return stubbedCreateAliasResult
    }
    // MARK: - createAliasAndAnotherItem
    var createAliasAndAnotherItemShareIdRequestThrowableError: Error?
    var closureCreateAliasAndAnotherItem: () -> () = {}
    var invokedCreateAliasAndAnotherItem = false
    var invokedCreateAliasAndAnotherItemCount = 0
    var invokedCreateAliasAndAnotherItemParameters: (shareId: String, request: CreateAliasAndAnotherItemRequest)?
    var invokedCreateAliasAndAnotherItemParametersList = [(shareId: String, request: CreateAliasAndAnotherItemRequest)]()
    var stubbedCreateAliasAndAnotherItemResult: CreateAliasAndAnotherItemResponse.Bundle!

    func createAliasAndAnotherItem(shareId: String, request: CreateAliasAndAnotherItemRequest) async throws -> CreateAliasAndAnotherItemResponse.Bundle {
        invokedCreateAliasAndAnotherItem = true
        invokedCreateAliasAndAnotherItemCount += 1
        invokedCreateAliasAndAnotherItemParameters = (shareId, request)
        invokedCreateAliasAndAnotherItemParametersList.append((shareId, request))
        if let error = createAliasAndAnotherItemShareIdRequestThrowableError {
            throw error
        }
        closureCreateAliasAndAnotherItem()
        return stubbedCreateAliasAndAnotherItemResult
    }
    // MARK: - trashItemRevisions
    var trashItemRevisionsShareIdThrowableError: Error?
    var closureTrashItemRevisions: () -> () = {}
    var invokedTrashItemRevisions = false
    var invokedTrashItemRevisionsCount = 0
    var invokedTrashItemRevisionsParameters: (items: [ItemRevision], shareId: String)?
    var invokedTrashItemRevisionsParametersList = [(items: [ItemRevision], shareId: String)]()
    var stubbedTrashItemRevisionsResult: [ModifiedItem]!

    func trashItemRevisions(_ items: [ItemRevision], shareId: String) async throws -> [ModifiedItem] {
        invokedTrashItemRevisions = true
        invokedTrashItemRevisionsCount += 1
        invokedTrashItemRevisionsParameters = (items, shareId)
        invokedTrashItemRevisionsParametersList.append((items, shareId))
        if let error = trashItemRevisionsShareIdThrowableError {
            throw error
        }
        closureTrashItemRevisions()
        return stubbedTrashItemRevisionsResult
    }
    // MARK: - untrashItemRevisions
    var untrashItemRevisionsShareIdThrowableError: Error?
    var closureUntrashItemRevisions: () -> () = {}
    var invokedUntrashItemRevisions = false
    var invokedUntrashItemRevisionsCount = 0
    var invokedUntrashItemRevisionsParameters: (items: [ItemRevision], shareId: String)?
    var invokedUntrashItemRevisionsParametersList = [(items: [ItemRevision], shareId: String)]()
    var stubbedUntrashItemRevisionsResult: [ModifiedItem]!

    func untrashItemRevisions(_ items: [ItemRevision], shareId: String) async throws -> [ModifiedItem] {
        invokedUntrashItemRevisions = true
        invokedUntrashItemRevisionsCount += 1
        invokedUntrashItemRevisionsParameters = (items, shareId)
        invokedUntrashItemRevisionsParametersList.append((items, shareId))
        if let error = untrashItemRevisionsShareIdThrowableError {
            throw error
        }
        closureUntrashItemRevisions()
        return stubbedUntrashItemRevisionsResult
    }
    // MARK: - deleteItemRevisions
    var deleteItemRevisionsShareIdSkipTrashThrowableError: Error?
    var closureDeleteItemRevisions: () -> () = {}
    var invokedDeleteItemRevisions = false
    var invokedDeleteItemRevisionsCount = 0
    var invokedDeleteItemRevisionsParameters: (items: [ItemRevision], shareId: String, skipTrash: Bool)?
    var invokedDeleteItemRevisionsParametersList = [(items: [ItemRevision], shareId: String, skipTrash: Bool)]()

    func deleteItemRevisions(_ items: [ItemRevision], shareId: String, skipTrash: Bool) async throws {
        invokedDeleteItemRevisions = true
        invokedDeleteItemRevisionsCount += 1
        invokedDeleteItemRevisionsParameters = (items, shareId, skipTrash)
        invokedDeleteItemRevisionsParametersList.append((items, shareId, skipTrash))
        if let error = deleteItemRevisionsShareIdSkipTrashThrowableError {
            throw error
        }
        closureDeleteItemRevisions()
    }
    // MARK: - updateItem
    var updateItemShareIdItemIdRequestThrowableError: Error?
    var closureUpdateItem: () -> () = {}
    var invokedUpdateItem = false
    var invokedUpdateItemCount = 0
    var invokedUpdateItemParameters: (shareId: String, itemId: String, request: UpdateItemRequest)?
    var invokedUpdateItemParametersList = [(shareId: String, itemId: String, request: UpdateItemRequest)]()
    var stubbedUpdateItemResult: ItemRevision!

    func updateItem(shareId: String, itemId: String, request: UpdateItemRequest) async throws -> ItemRevision {
        invokedUpdateItem = true
        invokedUpdateItemCount += 1
        invokedUpdateItemParameters = (shareId, itemId, request)
        invokedUpdateItemParametersList.append((shareId, itemId, request))
        if let error = updateItemShareIdItemIdRequestThrowableError {
            throw error
        }
        closureUpdateItem()
        return stubbedUpdateItemResult
    }
    // MARK: - updateLastUseTime
    var updateLastUseTimeShareIdItemIdLastUseTimeThrowableError: Error?
    var closureUpdateLastUseTime: () -> () = {}
    var invokedUpdateLastUseTime = false
    var invokedUpdateLastUseTimeCount = 0
    var invokedUpdateLastUseTimeParameters: (shareId: String, itemId: String, lastUseTime: TimeInterval)?
    var invokedUpdateLastUseTimeParametersList = [(shareId: String, itemId: String, lastUseTime: TimeInterval)]()
    var stubbedUpdateLastUseTimeResult: ItemRevision!

    func updateLastUseTime(shareId: String, itemId: String, lastUseTime: TimeInterval) async throws -> ItemRevision {
        invokedUpdateLastUseTime = true
        invokedUpdateLastUseTimeCount += 1
        invokedUpdateLastUseTimeParameters = (shareId, itemId, lastUseTime)
        invokedUpdateLastUseTimeParametersList.append((shareId, itemId, lastUseTime))
        if let error = updateLastUseTimeShareIdItemIdLastUseTimeThrowableError {
            throw error
        }
        closureUpdateLastUseTime()
        return stubbedUpdateLastUseTimeResult
    }
    // MARK: - moveItemIdFromShareIdRequest
    var moveItemIdFromShareIdRequestThrowableError: Error?
    var closureMoveItemIdFromShareIdRequest: () -> () = {}
    var invokedMoveItemIdFromShareIdRequest = false
    var invokedMoveItemIdFromShareIdRequestCount = 0
    var invokedMoveItemIdFromShareIdRequestParameters: (itemId: String, fromShareId: String, request: MoveItemRequest)?
    var invokedMoveItemIdFromShareIdRequestParametersList = [(itemId: String, fromShareId: String, request: MoveItemRequest)]()
    var stubbedMoveItemIdFromShareIdRequestResult: ItemRevision!

    func move(itemId: String, fromShareId: String, request: MoveItemRequest) async throws -> ItemRevision {
        invokedMoveItemIdFromShareIdRequest = true
        invokedMoveItemIdFromShareIdRequestCount += 1
        invokedMoveItemIdFromShareIdRequestParameters = (itemId, fromShareId, request)
        invokedMoveItemIdFromShareIdRequestParametersList.append((itemId, fromShareId, request))
        if let error = moveItemIdFromShareIdRequestThrowableError {
            throw error
        }
        closureMoveItemIdFromShareIdRequest()
        return stubbedMoveStringStringMoveItemRequestResult
    }
    // MARK: - moveFromShareIdRequest
    var moveFromShareIdRequestThrowableError: Error?
    var closureMoveFromShareIdRequest: () -> () = {}
    var invokedMoveFromShareIdRequest = false
    var invokedMoveFromShareIdRequestCount = 0
    var invokedMoveFromShareIdRequestParameters: (fromShareId: String, request: MoveItemsRequest)?
    var invokedMoveFromShareIdRequestParametersList = [(fromShareId: String, request: MoveItemsRequest)]()
    var stubbedMoveFromShareIdRequestResult: [ItemRevision]!

    func move(fromShareId: String, request: MoveItemsRequest) async throws -> [ItemRevision] {
        invokedMoveFromShareIdRequest = true
        invokedMoveFromShareIdRequestCount += 1
        invokedMoveFromShareIdRequestParameters = (fromShareId, request)
        invokedMoveFromShareIdRequestParametersList.append((fromShareId, request))
        if let error = moveFromShareIdRequestThrowableError {
            throw error
        }
        closureMoveFromShareIdRequest()
        return stubbedMoveStringMoveItemsRequestResult
    }
    // MARK: - pin
    var pinShareIdItemIdThrowableError: Error?
    var closurePin: () -> () = {}
    var invokedPin = false
    var invokedPinCount = 0
    var invokedPinParameters: (shareId: String, itemId: String)?
    var invokedPinParametersList = [(shareId: String, itemId: String)]()
    var stubbedPinResult: ItemRevision!

    func pin(shareId: String, itemId: String) async throws -> ItemRevision {
        invokedPin = true
        invokedPinCount += 1
        invokedPinParameters = (shareId, itemId)
        invokedPinParametersList.append((shareId, itemId))
        if let error = pinShareIdItemIdThrowableError {
            throw error
        }
        closurePin()
        return stubbedPinResult
    }
    // MARK: - unpin
    var unpinShareIdItemIdThrowableError: Error?
    var closureUnpin: () -> () = {}
    var invokedUnpin = false
    var invokedUnpinCount = 0
    var invokedUnpinParameters: (shareId: String, itemId: String)?
    var invokedUnpinParametersList = [(shareId: String, itemId: String)]()
    var stubbedUnpinResult: ItemRevision!

    func unpin(shareId: String, itemId: String) async throws -> ItemRevision {
        invokedUnpin = true
        invokedUnpinCount += 1
        invokedUnpinParameters = (shareId, itemId)
        invokedUnpinParametersList.append((shareId, itemId))
        if let error = unpinShareIdItemIdThrowableError {
            throw error
        }
        closureUnpin()
        return stubbedUnpinResult
    }
}
