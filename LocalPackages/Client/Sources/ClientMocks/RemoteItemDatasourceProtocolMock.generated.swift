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
import Entities
import Foundation

public final class RemoteItemDatasourceProtocolMock: @unchecked Sendable, RemoteItemDatasourceProtocol {

    public init() {}

    // MARK: - getItems
    public var getItemsUserIdShareIdEventStreamThrowableError1: Error?
    public var closureGetItems: () -> () = {}
    public var invokedGetItemsfunction = false
    public var invokedGetItemsCount = 0
    public var invokedGetItemsParameters: (userId: String, shareId: String, eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?)?
    public var invokedGetItemsParametersList = [(userId: String, shareId: String, eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?)]()
    public var stubbedGetItemsResult: [Item]!

    public func getItems(userId: String, shareId: String, eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?) async throws -> [Item] {
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
    // MARK: - getItem
    public var getItemUserIdShareIdItemIdEventTokenThrowableError3: Error?
    public var closureGetItem: () -> () = {}
    public var invokedGetItemfunction = false
    public var invokedGetItemCount = 0
    public var invokedGetItemParameters: (userId: String, shareId: String, itemId: String, eventToken: String)?
    public var invokedGetItemParametersList = [(userId: String, shareId: String, itemId: String, eventToken: String)]()
    public var stubbedGetItemResult: Item!

    public func getItem(userId: String, shareId: String, itemId: String, eventToken: String) async throws -> Item {
        invokedGetItemfunction = true
        invokedGetItemCount += 1
        invokedGetItemParameters = (userId, shareId, itemId, eventToken)
        invokedGetItemParametersList.append((userId, shareId, itemId, eventToken))
        if let error = getItemUserIdShareIdItemIdEventTokenThrowableError3 {
            throw error
        }
        closureGetItem()
        return stubbedGetItemResult
    }
    // MARK: - createItem
    public var createItemUserIdShareIdRequestThrowableError4: Error?
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
        if let error = createItemUserIdShareIdRequestThrowableError4 {
            throw error
        }
        closureCreateItem()
        return stubbedCreateItemResult
    }
    // MARK: - createAlias
    public var createAliasUserIdShareIdRequestThrowableError5: Error?
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
        if let error = createAliasUserIdShareIdRequestThrowableError5 {
            throw error
        }
        closureCreateAlias()
        return stubbedCreateAliasResult
    }
    // MARK: - createAliasAndAnotherItem
    public var createAliasAndAnotherItemUserIdShareIdRequestThrowableError6: Error?
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
        if let error = createAliasAndAnotherItemUserIdShareIdRequestThrowableError6 {
            throw error
        }
        closureCreateAliasAndAnotherItem()
        return stubbedCreateAliasAndAnotherItemResult
    }
    // MARK: - trashItem
    public var trashItemShareIdUserIdThrowableError7: Error?
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
        if let error = trashItemShareIdUserIdThrowableError7 {
            throw error
        }
        closureTrashItem()
        return stubbedTrashItemResult
    }
    // MARK: - untrashItem
    public var untrashItemShareIdUserIdThrowableError8: Error?
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
        if let error = untrashItemShareIdUserIdThrowableError8 {
            throw error
        }
        closureUntrashItem()
        return stubbedUntrashItemResult
    }
    // MARK: - deleteItem
    public var deleteItemShareIdSkipTrashUserIdThrowableError9: Error?
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
        if let error = deleteItemShareIdSkipTrashUserIdThrowableError9 {
            throw error
        }
        closureDeleteItem()
    }
    // MARK: - updateItem
    public var updateItemUserIdShareIdItemIdRequestThrowableError10: Error?
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
        if let error = updateItemUserIdShareIdItemIdRequestThrowableError10 {
            throw error
        }
        closureUpdateItem()
        return stubbedUpdateItemResult
    }
    // MARK: - updateLastUseTime
    public var updateLastUseTimeUserIdShareIdItemIdLastUseTimeThrowableError11: Error?
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
        if let error = updateLastUseTimeUserIdShareIdItemIdLastUseTimeThrowableError11 {
            throw error
        }
        closureUpdateLastUseTime()
        return stubbedUpdateLastUseTimeResult
    }
    // MARK: - move
    public var moveUserIdFromShareIdRequestThrowableError12: Error?
    public var closureMove: () -> () = {}
    public var invokedMovefunction = false
    public var invokedMoveCount = 0
    public var invokedMoveParameters: (userId: String, fromShareId: String, request: MoveItemsRequest)?
    public var invokedMoveParametersList = [(userId: String, fromShareId: String, request: MoveItemsRequest)]()
    public var stubbedMoveResult: [Item]!

    public func move(userId: String, fromShareId: String, request: MoveItemsRequest) async throws -> [Item] {
        invokedMovefunction = true
        invokedMoveCount += 1
        invokedMoveParameters = (userId, fromShareId, request)
        invokedMoveParametersList.append((userId, fromShareId, request))
        if let error = moveUserIdFromShareIdRequestThrowableError12 {
            throw error
        }
        closureMove()
        return stubbedMoveResult
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
    public var toggleAliasStatusUserIdShareIdItemIdEnabledThrowableError17: Error?
    public var closureToggleAliasStatus: () -> () = {}
    public var invokedToggleAliasStatusfunction = false
    public var invokedToggleAliasStatusCount = 0
    public var invokedToggleAliasStatusParameters: (userId: String, shareId: String, itemId: String, enabled: Bool)?
    public var invokedToggleAliasStatusParametersList = [(userId: String, shareId: String, itemId: String, enabled: Bool)]()
    public var stubbedToggleAliasStatusResult: Item!

    public func toggleAliasStatus(userId: String, shareId: String, itemId: String, enabled: Bool) async throws -> Item {
        invokedToggleAliasStatusfunction = true
        invokedToggleAliasStatusCount += 1
        invokedToggleAliasStatusParameters = (userId, shareId, itemId, enabled)
        invokedToggleAliasStatusParametersList.append((userId, shareId, itemId, enabled))
        if let error = toggleAliasStatusUserIdShareIdItemIdEnabledThrowableError17 {
            throw error
        }
        closureToggleAliasStatus()
        return stubbedToggleAliasStatusResult
    }
    // MARK: - resetHistory
    public var resetHistoryUserIdShareIdItemIdThrowableError18: Error?
    public var closureResetHistory: () -> () = {}
    public var invokedResetHistoryfunction = false
    public var invokedResetHistoryCount = 0
    public var invokedResetHistoryParameters: (userId: String, shareId: String, itemId: String)?
    public var invokedResetHistoryParametersList = [(userId: String, shareId: String, itemId: String)]()
    public var stubbedResetHistoryResult: Item!

    public func resetHistory(userId: String, shareId: String, itemId: String) async throws -> Item {
        invokedResetHistoryfunction = true
        invokedResetHistoryCount += 1
        invokedResetHistoryParameters = (userId, shareId, itemId)
        invokedResetHistoryParametersList.append((userId, shareId, itemId))
        if let error = resetHistoryUserIdShareIdItemIdThrowableError18 {
            throw error
        }
        closureResetHistory()
        return stubbedResetHistoryResult
    }
    // MARK: - importItems
    public var importItemsUserIdShareIdItemsThrowableError19: Error?
    public var closureImportItems: () -> () = {}
    public var invokedImportItemsfunction = false
    public var invokedImportItemsCount = 0
    public var invokedImportItemsParameters: (userId: String, shareId: String, items: [ItemToImport])?
    public var invokedImportItemsParametersList = [(userId: String, shareId: String, items: [ItemToImport])]()
    public var stubbedImportItemsResult: [Item]!

    public func importItems(userId: String, shareId: String, items: [ItemToImport]) async throws -> [Item] {
        invokedImportItemsfunction = true
        invokedImportItemsCount += 1
        invokedImportItemsParameters = (userId, shareId, items)
        invokedImportItemsParametersList.append((userId, shareId, items))
        if let error = importItemsUserIdShareIdItemsThrowableError19 {
            throw error
        }
        closureImportItems()
        return stubbedImportItemsResult
    }
}
