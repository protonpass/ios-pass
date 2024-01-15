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

import Core
import Entities
import Foundation

// sourcery: AutoMockable
public protocol RemoteItemDatasourceProtocol: Sendable {
    /// Get all item revisions of a share
    func getItems(shareId: String, eventStream: VaultSyncEventStream?) async throws -> [Item]
    func getItemRevisions(shareId: String, itemId: String, lastToken: String?) async throws -> Paginated<Item>
    func createItem(shareId: String, request: CreateItemRequest) async throws -> Item
    func createAlias(shareId: String, request: CreateCustomAliasRequest) async throws -> Item
    func createAliasAndAnotherItem(shareId: String, request: CreateAliasAndAnotherItemRequest)
        async throws -> CreateAliasAndAnotherItemResponse.Bundle
    func trashItem(_ items: [Item], shareId: String) async throws -> [ModifiedItem]
    func untrashItem(_ items: [Item], shareId: String) async throws -> [ModifiedItem]
    func deleteItem(_ items: [Item], shareId: String, skipTrash: Bool) async throws
    func updateItem(shareId: String, itemId: String, request: UpdateItemRequest) async throws -> Item
    func updateLastUseTime(shareId: String, itemId: String, lastUseTime: TimeInterval) async throws -> Item
    func move(itemId: String, fromShareId: String, request: MoveItemRequest) async throws -> Item
    func move(fromShareId: String, request: MoveItemsRequest) async throws -> [Item]
    func pin(item: any ItemIdentifiable) async throws -> Item
    func unpin(item: any ItemIdentifiable) async throws -> Item
}

public final class RemoteItemDatasource: RemoteDatasource, RemoteItemDatasourceProtocol {}

public extension RemoteItemDatasource {
    func getItems(shareId: String,
                  eventStream: VaultSyncEventStream?) async throws -> [Item] {
        var itemRevisions = [Item]()
        var sinceToken: String?
        while true {
            let endpoint = GetItemsEndpoint(shareId: shareId,
                                            sinceToken: sinceToken,
                                            pageSize: Constants.Utils.defaultPageSize)
            let response = try await exec(endpoint: endpoint)

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

    func getItemRevisions(shareId: String, itemId: String, lastToken: String?) async throws -> Paginated<Item> {
        let endpoint = GetItemRevisionsEndpoint(shareId: shareId, itemId: itemId, sinceToken: lastToken)
        let response = try await exec(endpoint: endpoint)
        return Paginated(lastToken: response.revisions.lastToken,
                         data: response.revisions.revisionsData,
                         total: response.revisions.total)
    }

    func createItem(shareId: String, request: CreateItemRequest) async throws -> Item {
        let endpoint = CreateItemEndpoint(shareId: shareId, request: request)
        let response = try await exec(endpoint: endpoint)
        return response.item
    }

    func createAlias(shareId: String, request: CreateCustomAliasRequest) async throws -> Item {
        let endpoint = CreateCustomAliasEndpoint(shareId: shareId, request: request)
        let response = try await exec(endpoint: endpoint)
        return response.item
    }

    func createAliasAndAnotherItem(shareId: String, request: CreateAliasAndAnotherItemRequest)
        async throws -> CreateAliasAndAnotherItemResponse.Bundle {
        let endpoint = CreateAliasAndAnotherItemEndpoint(shareId: shareId, request: request)
        let response = try await exec(endpoint: endpoint)
        return response.bundle
    }

    func trashItem(_ items: [Item], shareId: String) async throws -> [ModifiedItem] {
        let endpoint = TrashItemsEndpoint(shareId: shareId, items: items)
        let response = try await exec(endpoint: endpoint)
        return response.items
    }

    func untrashItem(_ items: [Item], shareId: String) async throws -> [ModifiedItem] {
        let endpoint = UntrashItemsEndpoint(shareId: shareId, items: items)
        let response = try await exec(endpoint: endpoint)
        return response.items
    }

    func deleteItem(_ items: [Item],
                    shareId: String,
                    skipTrash: Bool) async throws {
        let endpoint = DeleteItemsEndpoint(shareId: shareId,
                                           items: items,
                                           skipTrash: skipTrash)
        _ = try await exec(endpoint: endpoint)
    }

    func updateItem(shareId: String,
                    itemId: String,
                    request: UpdateItemRequest) async throws -> Item {
        let endpoint = UpdateItemEndpoint(shareId: shareId,
                                          itemId: itemId,
                                          request: request)
        let response = try await exec(endpoint: endpoint)
        return response.item
    }

    func updateLastUseTime(shareId: String,
                           itemId: String,
                           lastUseTime: TimeInterval) async throws -> Item {
        let endpoint = UpdateLastUseTimeEndpoint(shareId: shareId,
                                                 itemId: itemId,
                                                 lastUseTime: lastUseTime)
        let response = try await exec(endpoint: endpoint)
        return response.revision
    }

    func move(itemId: String,
              fromShareId: String,
              request: MoveItemRequest) async throws -> Item {
        let endpoint = MoveItemEndpoint(request: request, itemId: itemId, fromShareId: fromShareId)
        let response = try await exec(endpoint: endpoint)
        return response.item
    }

    func move(fromShareId: String, request: MoveItemsRequest) async throws -> [Item] {
        let endpoint = MoveItemsEndpoint(request: request, fromShareId: fromShareId)
        let response = try await exec(endpoint: endpoint)
        return response.items
    }

    func pin(item: any ItemIdentifiable) async throws -> Item {
        let endpoint = PinItemEndpoint(shareId: item.shareId, itemId: item.itemId)
        let response = try await exec(endpoint: endpoint)
        return response.item
    }

    func unpin(item: any ItemIdentifiable) async throws -> Item {
        let endpoint = UnpinItemEndpoint(shareId: item.shareId, itemId: item.itemId)
        let response = try await exec(endpoint: endpoint)
        return response.item
    }
}
