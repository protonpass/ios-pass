//
// Repository.swift
// Proton Pass - Created on 05/08/2022.
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

public protocol RepositoryProtocol {
    func getShares(forceUpdate: Bool) async throws -> [Share]
    func getShareKey(forceUpdate: Bool,
                     shareId: String,
                     page: Int,
                     pageSize: Int) async throws -> ShareKey
    func getItems(forceUpdate: Bool,
                  shareId: String,
                  page: Int,
                  pageSize: Int) async throws -> Items
    func createItem(shareId: String, requestBody: CreateItemRequestBody) async throws -> Item
}

public final class Repository {
    private let userId: String
    private let localDatasource: LocalDatasourceProtocol
    private let remoteDatasource: RemoteDatasourceProtocol

    public init(userId: String,
                localDatasource: LocalDatasourceProtocol,
                remoteDatasource: RemoteDatasourceProtocol) {
        self.userId = userId
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
    }
}

extension Repository: RepositoryProtocol {
    public func getShares(forceUpdate: Bool) async throws -> [Share] {
        PPLogger.shared?.log("Getting shares")
        if forceUpdate {
            PPLogger.shared?.log("Force update getting shares")
            return try await getSharesFromRemoteAndSaveToLocal()
        }

        let localShares = try await localDatasource.fetchShares(userId: userId)
        if localShares.isEmpty {
            PPLogger.shared?.log("No shares in local db => Fetching from remote...")
            return try await getSharesFromRemoteAndSaveToLocal()
        }

        PPLogger.shared?.log("Found \(localShares.count) shares in local db")
        return localShares
    }

    private func getSharesFromRemoteAndSaveToLocal() async throws -> [Share] {
        let remoteShares = try await remoteDatasource.getShares()
        try await localDatasource.insertShares(remoteShares, userId: userId)
        PPLogger.shared?.log("Fetched \(remoteShares.count) shares from remote and saved to local")
        return remoteShares
    }

    public func getShareKey(forceUpdate: Bool,
                            shareId: String,
                            page: Int,
                            pageSize: Int) async throws -> ShareKey {
        if forceUpdate {
            return try await getShareKeyFromRemoteAndSaveToLocal(shareId: shareId,
                                                                 page: page,
                                                                 pageSize: pageSize)
        }

        let localShareKey = try await localDatasource.fetchShareKey(shareId: shareId,
                                                                    page: page,
                                                                    pageSize: pageSize)
        if localShareKey.isEmpty {
            return try await getShareKeyFromRemoteAndSaveToLocal(shareId: shareId,
                                                                 page: page,
                                                                 pageSize: pageSize)
        }

        return localShareKey
    }

    private func getShareKeyFromRemoteAndSaveToLocal(shareId: String,
                                                     page: Int,
                                                     pageSize: Int) async throws -> ShareKey {
        let remoteShareKey = try await remoteDatasource.getShareKey(shareId: shareId,
                                                                    page: page,
                                                                    pageSize: pageSize)
        try await localDatasource.insertShareKey(remoteShareKey, shareId: shareId)
        return remoteShareKey
    }

    public func getItems(forceUpdate: Bool,
                         shareId: String,
                         page: Int,
                         pageSize: Int) async throws -> Items {
        PPLogger.shared?.log("Getting items for shareId \(shareId)")
        if forceUpdate {
            PPLogger.shared?.log("Force update getting items for shareId \(shareId)")
            return try await getItemsFromRemoteAndSaveToLocal(shareId: shareId,
                                                              page: page,
                                                              pageSize: pageSize)
        }

        let localItems = try await localDatasource.fetchItems(shareId: shareId,
                                                              page: page,
                                                              pageSize: pageSize)

        if localItems.isEmpty {
            PPLogger.shared?.log("No items for shareId \(shareId) in local db => Fetching from remote...")
            return try await getItemsFromRemoteAndSaveToLocal(shareId: shareId,
                                                              page: page,
                                                              pageSize: pageSize)
        }

        PPLogger.shared?.log("Found \(localItems.revisionsData.count) items in local db for shareId \(shareId)")
        return localItems
    }

    private func getItemsFromRemoteAndSaveToLocal(shareId: String,
                                                  page: Int,
                                                  pageSize: Int) async throws -> Items {
        let remoteItems = try await remoteDatasource.getItems(shareId: shareId,
                                                              page: page,
                                                              pageSize: pageSize)
        try await localDatasource.insertItems(remoteItems.revisionsData, shareId: shareId)
        PPLogger.shared?.log("""
Fetched \(remoteItems.revisionsData.count) items from remote and saved to local for shareId \(shareId)
""")
        return remoteItems
    }

    public func createItem(shareId: String,
                           requestBody: CreateItemRequestBody) async throws -> Item {
        let createdItem = try await remoteDatasource.createItem(shareId: shareId,
                                                                requestBody: requestBody)
        try await localDatasource.insertItems([createdItem], shareId: shareId)
        return createdItem
    }
}
