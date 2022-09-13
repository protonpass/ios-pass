//
// RemoteItemRevisionDatasource.swift
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

import Foundation

public protocol RemoteItemRevisionDatasourceProtocol: BaseRemoteDatasourceProtocol {
    /// Get all item revisions of a share
    func getItemRevisions(shareId: String) async throws -> [ItemRevision]
    func createItem(shareId: String, request: CreateItemRequest) async throws -> ItemRevision
    func trashItems(shareId: String, request: TrashItemsRequest) async throws -> [ItemToBeTrashed]
    func deleteItems(shareId: String, request: DeleteItemsRequest) async throws
    func updateItem(shareId: String, itemId: String, request: UpdateItemRequest) async throws -> ItemRevision
}

public extension RemoteItemRevisionDatasourceProtocol {
    func getItemRevisions(shareId: String) async throws -> [ItemRevision] {
        var itemRevisions = [ItemRevision]()
        var page = 0
        while true {
            let endpoint = GetItemsEndpoint(credential: authCredential,
                                            shareId: shareId,
                                            page: page,
                                            pageSize: kDefaultPageSize)
            let response = try await apiService.exec(endpoint: endpoint)

            itemRevisions += response.items.revisionsData
            if response.items.revisionsData.count < kDefaultPageSize {
                break
            } else {
                page += 1
            }
        }
        return itemRevisions
    }

    func createItem(shareId: String,
                    request: CreateItemRequest) async throws -> ItemRevision {
        let endpoint = CreateItemEndpoint(credential: authCredential,
                                          shareId: shareId,
                                          request: request)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.item
    }

    func trashItems(shareId: String, request: TrashItemsRequest) async throws -> [ItemToBeTrashed] {
        let endpoint = TrashItemsEndpoint(credential: authCredential,
                                          shareId: shareId,
                                          request: request)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.items
    }

    func deleteItems(shareId: String, request: DeleteItemsRequest) async throws {
        let endpoint = DeleteItemsEndpoint(credential: authCredential,
                                           shareId: shareId,
                                           request: request)
        _ = try await apiService.exec(endpoint: endpoint)
    }

    func updateItem(shareId: String,
                    itemId: String,
                    request: UpdateItemRequest) async throws -> ItemRevision {
        let endpoint = UpdateItemEndpoint(credential: authCredential,
                                          shareId: shareId,
                                          itemId: itemId,
                                          request: request)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.item
    }
}

public final class RemoteItemRevisionDatasource: BaseRemoteDatasource {}

extension RemoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol {}
