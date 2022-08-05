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

import Foundation

public protocol RepositoryProtocol {
    func getShares(forceUpdate: Bool) async throws -> [Share]
    func getShareKey(forceUpdate: Bool,
                     shareId: String,
                     page: Int,
                     pageSize: Int) async throws -> ShareKey
}

public final class Repository {
    private let userId: String
    private let localDatasource: LocalDatasourceProtocol
    private let remoteDatasource: RemoteDatasourceProtocol

    init(userId: String,
         localDatasource: LocalDatasourceProtocol,
         remoteDatasource: RemoteDatasourceProtocol) {
        self.userId = userId
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
    }
}

extension Repository: RepositoryProtocol {
    public func getShares(forceUpdate: Bool) async throws -> [Share] {
        if forceUpdate {
            return try await getSharesFromRemoteAndSaveToLocal()
        }

        let localShares = try await localDatasource.fetchShares(forUserId: userId)
        if localShares.isEmpty {
            return try await getSharesFromRemoteAndSaveToLocal()
        }

        return localShares
    }

    private func getSharesFromRemoteAndSaveToLocal() async throws -> [Share] {
        let remoteShares = try await remoteDatasource.getShares()
        try await localDatasource.insertShares(remoteShares, withUserId: userId)
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

        let localShareKey = try await localDatasource.fetchShareKey(forShareId: shareId,
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
        try await localDatasource.insertShareKey(remoteShareKey, withShareId: shareId)
        return remoteShareKey
    }
}
