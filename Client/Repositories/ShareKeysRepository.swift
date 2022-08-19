//
// ShareKeysRepository.swift
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

import CoreData
import ProtonCore_Networking
import ProtonCore_Services

public enum ShareKeysRepositoryError: Error {
    case failedToGetLatestVaultItemKey
}

public protocol ShareKeysRepositoryProtocol {
    var localShareKeysDatasource: LocalShareKeysDatasourceProtocol { get }
    var remoteShareKeysDatasource: RemoteShareKeysDatasourceProtocol { get }

    func getShareKeys(shareId: String,
                      page: Int,
                      pageSize: Int,
                      forceRefresh: Bool) async throws -> ShareKeys
    /// Get vault & item key pair with highest rotation
    func getLatestVaultItemKey(shareId: String,
                               forceRefresh: Bool) async throws -> (VaultKey, ItemKey)
}

public extension ShareKeysRepositoryProtocol {
    func getShareKeys(shareId: String,
                      page: Int,
                      pageSize: Int,
                      forceRefresh: Bool) async throws -> ShareKeys {
        if forceRefresh {
            return try await getFromRemoteAndSaveToLocal(shareId: shareId,
                                                         page: page,
                                                         pageSize: pageSize)
        }

        let localShareKeys =
        try await localShareKeysDatasource.getShareKeys(shareId: shareId,
                                                        page: page,
                                                        pageSize: pageSize)

        if localShareKeys.isEmpty {
            return try await getFromRemoteAndSaveToLocal(shareId: shareId,
                                                         page: page,
                                                         pageSize: pageSize)
        }

        return localShareKeys
    }

    func getLatestVaultItemKey(shareId: String,
                               forceRefresh: Bool) async throws -> (VaultKey, ItemKey) {
        // Retrieve share keys normally
        let shareKeys = try await getShareKeys(shareId: shareId,
                                               page: 0,
                                               pageSize: kDefaultPageSize,
                                               forceRefresh: forceRefresh)

        if let latestVaultItemKey = shareKeys.latestVaultItemKey() {
            return latestVaultItemKey
        }

        // Force refresh when first retrieval attempt fails for any reasons
        let refreshedShareKeys = try await getShareKeys(shareId: shareId,
                                                        page: 0,
                                                        pageSize: kDefaultPageSize,
                                                        forceRefresh: true)

        if let refreshedVaultItemKey = refreshedShareKeys.latestVaultItemKey() {
            return refreshedVaultItemKey
        }

        // Something really nasty is going on
        throw ShareKeysRepositoryError.failedToGetLatestVaultItemKey
    }

    private func getFromRemoteAndSaveToLocal(shareId: String,
                                             page: Int,
                                             pageSize: Int) async throws -> ShareKeys {
        let remoteShareKeys = try await remoteShareKeysDatasource.getShareKeys(shareId: shareId,
                                                                               page: page,
                                                                               pageSize: pageSize)
        try await localShareKeysDatasource.upsertShareKeys(remoteShareKeys, shareId: shareId)
        return remoteShareKeys
    }
}

public struct ShareKeysRepository: ShareKeysRepositoryProtocol {
    public let localShareKeysDatasource: LocalShareKeysDatasourceProtocol
    public let remoteShareKeysDatasource: RemoteShareKeysDatasourceProtocol

    public init(localShareKeysDatasource: LocalShareKeysDatasourceProtocol,
                remoteShareKeysDatasource: RemoteShareKeysDatasourceProtocol) {
        self.localShareKeysDatasource = localShareKeysDatasource
        self.remoteShareKeysDatasource = remoteShareKeysDatasource
    }

    public init(container: NSPersistentContainer,
                authCredential: AuthCredential,
                apiService: APIService) {
        let localItemKeyDatasource = LocalItemKeyDatasource(container: container)
        let localVaultKeyDatasource = LocalVaultKeyDatasource(container: container)
        self.localShareKeysDatasource =
        LocalShareKeysDatasource(localItemKeyDatasource: localItemKeyDatasource,
                                 localVaultKeyDatasource: localVaultKeyDatasource)
        self.remoteShareKeysDatasource = RemoteShareKeysDatasource(authCredential: authCredential,
                                                                   apiService: apiService)
    }
}
