//
// RemoteItemDatasource.swift
// Proton Pass - Created on 16/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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

@preconcurrency import Combine
import Core
import Entities
import Foundation

// sourcery: AutoMockable
public protocol RemoteItemDatasourceProtocol: Sendable {
    /// Get all item revisions of a share
    func getItems(userId: String,
                  shareId: String,
                  eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?) async throws
        -> [Item]
    func getItemRevisions(userId: String, shareId: String, itemId: String, lastToken: String?) async throws
        -> Paginated<Item>
    func getItem(userId: String,
                 shareId: String,
                 itemId: String,
                 eventToken: String) async throws -> Item
    func createItem(userId: String, shareId: String, request: CreateItemRequest) async throws -> Item
    func createAlias(userId: String, shareId: String, request: CreateCustomAliasRequest) async throws -> Item
    func createAliasAndAnotherItem(userId: String, shareId: String, request: CreateAliasAndAnotherItemRequest)
        async throws -> CreateAliasAndAnotherItemResponse.Bundle
    func trashItem(_ items: [Item], shareId: String, userId: String) async throws -> [ModifiedItem]
    func untrashItem(_ items: [Item], shareId: String, userId: String) async throws -> [ModifiedItem]
    func deleteItem(_ items: [Item], shareId: String, skipTrash: Bool, userId: String) async throws
    func updateItem(userId: String,
                    shareId: String,
                    itemId: String,
                    request: UpdateItemRequest) async throws
        -> Item
    func updateLastUseTime(userId: String,
                           shareId: String,
                           itemId: String,
                           lastUseTime: TimeInterval) async throws -> Item
    func move(userId: String, fromShareId: String, request: MoveItemsRequest) async throws -> [Item]
    func pin(userId: String, item: any ItemIdentifiable) async throws -> Item
    func unpin(userId: String, item: any ItemIdentifiable) async throws -> Item
    func updateItemFlags(userId: String,
                         itemId: String,
                         shareId: String,
                         request: UpdateItemFlagsRequest) async throws -> Item

    func createPendingAliasesItem(userId: String,
                                  shareId: String,
                                  request: CreateAliasesFromPendingRequest) async throws -> [Item]
    func toggleAliasStatus(userId: String, shareId: String, itemId: String, enabled: Bool) async throws -> Item
    func resetHistory(userId: String, shareId: String, itemId: String) async throws -> Item
    func importItems(userId: String, shareId: String, items: [ItemToImport]) async throws -> [Item]
}

public final class RemoteItemDatasource: RemoteDatasource, RemoteItemDatasourceProtocol, @unchecked Sendable {}

public extension RemoteItemDatasource {
    func getItems(userId: String,
                  shareId: String,
                  eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?) async throws -> [Item] {
        var itemRevisions = [Item]()
        var sinceToken: String?
        while true {
            let endpoint = GetItemsEndpoint(shareId: shareId,
                                            sinceToken: sinceToken,
                                            pageSize: Constants.Utils.defaultPageSize)
            let response = try await exec(userId: userId, endpoint: endpoint)

            itemRevisions += response.items.revisionsData
            sinceToken = response.items.lastToken
            eventStream?.send(.getRemoteItems(.init(shareId: shareId,
                                                    total: response.items.total,
                                                    downloaded: itemRevisions.count)))
            if itemRevisions.count >= response.items.total {
                break
            }
        }
        return itemRevisions
    }

    func getItemRevisions(userId: String,
                          shareId: String,
                          itemId: String,
                          lastToken: String?) async throws -> Paginated<Item> {
        let endpoint = GetItemRevisionsEndpoint(shareId: shareId, itemId: itemId, sinceToken: lastToken)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return Paginated(lastToken: response.revisions.lastToken,
                         data: response.revisions.revisionsData,
                         total: response.revisions.total)
    }

    func getItem(userId: String,
                 shareId: String,
                 itemId: String,
                 eventToken: String) async throws -> Item {
        let endpoint = GetSpecificItemEndpoint(shareId: shareId, itemId: itemId, eventToken: eventToken)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.item
    }

    func createItem(userId: String, shareId: String, request: CreateItemRequest) async throws -> Item {
        let endpoint = CreateItemEndpoint(shareId: shareId, request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.item
    }

    func createAlias(userId: String, shareId: String, request: CreateCustomAliasRequest) async throws -> Item {
        let endpoint = CreateCustomAliasEndpoint(shareId: shareId, request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.item
    }

    func createAliasAndAnotherItem(userId: String, shareId: String, request: CreateAliasAndAnotherItemRequest)
        async throws -> CreateAliasAndAnotherItemResponse.Bundle {
        let endpoint = CreateAliasAndAnotherItemEndpoint(shareId: shareId, request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.bundle
    }

    func trashItem(_ items: [Item], shareId: String, userId: String) async throws -> [ModifiedItem] {
        let endpoint = TrashItemsEndpoint(shareId: shareId, items: items)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.items
    }

    func untrashItem(_ items: [Item], shareId: String, userId: String) async throws -> [ModifiedItem] {
        let endpoint = UntrashItemsEndpoint(shareId: shareId, items: items)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.items
    }

    func deleteItem(_ items: [Item],
                    shareId: String,
                    skipTrash: Bool,
                    userId: String) async throws {
        let endpoint = DeleteItemsEndpoint(shareId: shareId,
                                           items: items,
                                           skipTrash: skipTrash)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func updateItem(userId: String,
                    shareId: String,
                    itemId: String,
                    request: UpdateItemRequest) async throws -> Item {
        let endpoint = UpdateItemEndpoint(shareId: shareId,
                                          itemId: itemId,
                                          request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.item
    }

    func updateLastUseTime(userId: String,
                           shareId: String,
                           itemId: String,
                           lastUseTime: TimeInterval) async throws -> Item {
        let endpoint = UpdateLastUseTimeEndpoint(shareId: shareId,
                                                 itemId: itemId,
                                                 lastUseTime: lastUseTime)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.revision
    }

    func move(userId: String, fromShareId: String, request: MoveItemsRequest) async throws -> [Item] {
        let endpoint = MoveItemsEndpoint(request: request, fromShareId: fromShareId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.items
    }

    func pin(userId: String, item: any ItemIdentifiable) async throws -> Item {
        let endpoint = PinItemEndpoint(shareId: item.shareId, itemId: item.itemId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.item
    }

    func unpin(userId: String, item: any ItemIdentifiable) async throws -> Item {
        let endpoint = UnpinItemEndpoint(shareId: item.shareId, itemId: item.itemId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.item
    }

    func updateItemFlags(userId: String,
                         itemId: String,
                         shareId: String,
                         request: UpdateItemFlagsRequest) async throws -> Item {
        let endpoint = UpdateItemFlagsEndpoint(shareId: shareId, itemId: itemId, request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.item
    }

    func createPendingAliasesItem(userId: String,
                                  shareId: String,
                                  request: CreateAliasesFromPendingRequest) async throws -> [Item] {
        let endpoint = CreateAliasesFromPendingEndpoint(shareId: shareId, request: request)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.revisions.revisionsData
    }

    func toggleAliasStatus(userId: String,
                           shareId: String,
                           itemId: String,
                           enabled: Bool) async throws -> Item {
        let endpoint = ChangeAliasStatusEndpoint(shareId: shareId, itemId: itemId, enabled: enabled)
        let result = try await exec(userId: userId, endpoint: endpoint)
        return result.item
    }

    func resetHistory(userId: String, shareId: String, itemId: String) async throws -> Item {
        let endpoint = ResetHistoryEndpoint(shareId: shareId, itemId: itemId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.item
    }

    func importItems(userId: String, shareId: String, items: [ItemToImport]) async throws -> [Item] {
        let endpoint = ImportItemsEndpoint(shareId: shareId, items: items)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.revisions.revisionsData
    }
}
