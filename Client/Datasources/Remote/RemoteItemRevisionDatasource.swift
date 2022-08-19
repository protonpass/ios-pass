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
    func getItemRevisions(shareId: String,
                          page: Int,
                          pageSize: Int) async throws -> ItemRevisionList
    func createItem(shareId: String, request: CreateItemRequest) async throws -> ItemRevision
}

public extension RemoteItemRevisionDatasourceProtocol {
    func getItemRevisions(shareId: String,
                          page: Int,
                          pageSize: Int) async throws -> ItemRevisionList {
        let endpoint = GetItemsEndpoint(credential: authCredential,
                                        shareId: shareId,
                                        page: page,
                                        pageSize: pageSize)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.items
    }

    func createItem(shareId: String,
                    request: CreateItemRequest) async throws -> ItemRevision {
        let endpoint = CreateItemEndpoint(credential: authCredential,
                                          shareId: shareId,
                                          request: request)
        let response = try await apiService.exec(endpoint: endpoint)
        return response.item
    }
}

public final class RemoteItemRevisionDatasource: BaseRemoteDatasource {}

extension RemoteItemRevisionDatasource: RemoteItemRevisionDatasourceProtocol {}
