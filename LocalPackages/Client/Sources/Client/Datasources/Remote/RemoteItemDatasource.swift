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

import Entities
import Foundation

public protocol RemoteItemDatasourceProtocol {
    /// Get all item revisions of a share
    func getItemRevisions(shareId: String, eventStream: VaultSyncEventStream?) async throws -> [ItemRevision]
    func createItem(shareId: String, request: CreateItemRequest) async throws -> ItemRevision
    func createAlias(shareId: String, request: CreateCustomAliasRequest) async throws -> ItemRevision
    func createAliasAndAnotherItem(shareId: String, request: CreateAliasAndAnotherItemRequest)
        async throws -> CreateAliasAndAnotherItemResponse.Bundle
    func trashItemRevisions(_ items: [ItemRevision], shareId: String) async throws -> [ModifiedItem]
    func untrashItemRevisions(_ items: [ItemRevision], shareId: String) async throws -> [ModifiedItem]
    func deleteItemRevisions(_ items: [ItemRevision], shareId: String, skipTrash: Bool) async throws
    func updateItem(shareId: String, itemId: String, request: UpdateItemRequest) async throws -> ItemRevision
    func updateLastUseTime(shareId: String, itemId: String, lastUseTime: TimeInterval) async throws -> ItemRevision
    func move(itemId: String, fromShareId: String, request: MoveItemRequest) async throws -> ItemRevision
    func move(fromShareId: String, request: MoveItemsRequest) async throws -> [ItemRevision]
}

public final class RemoteItemDatasource: RemoteDatasource, RemoteItemDatasourceProtocol {}

public extension RemoteItemDatasource {
    func getItemRevisions(shareId: String,
                          eventStream: VaultSyncEventStream?) async throws -> [ItemRevision] {
        var itemRevisions = [ItemRevision]()
        var sinceToken: String?
        while true {
            let endpoint = GetItemsEndpoint(shareId: shareId,
                                            sinceToken: sinceToken,
                                            pageSize: kDefaultPageSize)
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

    func createItem(shareId: String, request: CreateItemRequest) async throws -> ItemRevision {
        let endpoint = CreateItemEndpoint(shareId: shareId, request: request)
        let response = try await exec(endpoint: endpoint)
        return response.item
    }

    func createAlias(shareId: String, request: CreateCustomAliasRequest) async throws -> ItemRevision {
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

    func trashItemRevisions(_ items: [ItemRevision], shareId: String) async throws -> [ModifiedItem] {
        let endpoint = TrashItemsEndpoint(shareId: shareId, items: items)
        let response = try await exec(endpoint: endpoint)
        return response.items
    }

    func untrashItemRevisions(_ items: [ItemRevision], shareId: String) async throws -> [ModifiedItem] {
        let endpoint = UntrashItemsEndpoint(shareId: shareId, items: items)
        let response = try await exec(endpoint: endpoint)
        return response.items
    }

    func deleteItemRevisions(_ items: [ItemRevision],
                             shareId: String,
                             skipTrash: Bool) async throws {
        let endpoint = DeleteItemsEndpoint(shareId: shareId,
                                           items: items,
                                           skipTrash: skipTrash)
        _ = try await exec(endpoint: endpoint)
    }

    func updateItem(shareId: String,
                    itemId: String,
                    request: UpdateItemRequest) async throws -> ItemRevision {
        let endpoint = UpdateItemEndpoint(shareId: shareId,
                                          itemId: itemId,
                                          request: request)
        let response = try await exec(endpoint: endpoint)
        return response.item
    }

    func updateLastUseTime(shareId: String,
                           itemId: String,
                           lastUseTime: TimeInterval) async throws -> ItemRevision {
        let endpoint = UpdateLastUseTimeEndpoint(shareId: shareId,
                                                 itemId: itemId,
                                                 lastUseTime: lastUseTime)
        let response = try await exec(endpoint: endpoint)
        return response.revision
    }

    func move(itemId: String,
              fromShareId: String,
              request: MoveItemRequest) async throws -> ItemRevision {
        let endpoint = MoveItemEndpoint(request: request, itemId: itemId, fromShareId: fromShareId)
        let response = try await exec(endpoint: endpoint)
        return response.item
    }

    func move(fromShareId: String, request: MoveItemsRequest) async throws -> [ItemRevision] {
        let endpoint = MoveItemsEndpoint(request: request, fromShareId: fromShareId)
        let response = try await exec(endpoint: endpoint)
        return response.items
    }
}
