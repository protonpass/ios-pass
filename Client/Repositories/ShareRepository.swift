//
// ShareRepository.swift
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
import CoreData
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services

public protocol ShareRepositoryProtocol {
    var userData: UserData { get }
    var localShareDatasource: LocalShareDatasourceProtocol { get }
    var remoteShareDatasouce: RemoteShareDatasourceProtocol { get }
    var vaultItemKeysRepository: VaultItemKeysRepositoryProtocol { get }

    func getShares(forceRefresh: Bool) async throws -> [Share]
    func getShare(shareId: String) async throws -> Share
    func getVaults(forceRefresh: Bool) async throws -> [VaultProtocol]
    @discardableResult
    func createVault(request: CreateVaultRequest) async throws -> Share
}

public extension ShareRepositoryProtocol {
    func getShares(forceRefresh: Bool = false) async throws -> [Share] {
        PPLogger.shared?.log("Getting shares")
        if forceRefresh {
            PPLogger.shared?.log("Force refresh shares")
            return try await getSharesFromRemoteAndSaveToLocal()
        }

        let localShares = try await localShareDatasource.getAllShares(userId: userData.user.ID)
        if localShares.isEmpty {
            PPLogger.shared?.log("No shares in local => Fetching from remote...")
            return try await getSharesFromRemoteAndSaveToLocal()
        }

        PPLogger.shared?.log("Found \(localShares.count) shares in local")
        return localShares
    }

    private func getSharesFromRemoteAndSaveToLocal() async throws -> [Share] {
        PPLogger.shared?.log("Getting shares from remote")
        let remoteShares = try await remoteShareDatasouce.getShares()
        PPLogger.shared?.log("Saving remote shares to local")
        try await localShareDatasource.upsertShares(remoteShares, userId: userData.user.ID)
        return remoteShares
    }

    func getShare(shareId: String) async throws -> Share {
        if let localShare = try await localShareDatasource.getShare(userId: userData.user.ID,
                                                                    shareId: shareId) {
            return localShare
        }
        return try await remoteShareDatasouce.getShare(shareId: shareId)
    }

    func getVaults(forceRefresh: Bool) async throws -> [VaultProtocol] {
        PPLogger.shared?.log("Getting vaults")
        let shares = try await getShares(forceRefresh: forceRefresh)

        var vaults: [VaultProtocol] = []
        for share in shares where share.shareType == .vault {
            let vaultKeys =
            try await self.vaultItemKeysRepository.getVaultKeys(shareId: share.shareID,
                                                                forceRefresh: forceRefresh)
            let shareContent = try share.getShareContent(userData: userData,
                                                         vaultKeys: vaultKeys)
            switch shareContent {
            case .vault(let vault):
                vaults.append(vault)
            default:
                break
            }
        }
        return vaults
    }

    func createVault(request: CreateVaultRequest) async throws -> Share {
        PPLogger.shared?.log("Creating vault")
        let createdVault = try await remoteShareDatasouce.createVault(request: request)
        PPLogger.shared?.log("Saving newly create vault to local")
        try await localShareDatasource.upsertShares([createdVault], userId: userData.user.ID)
        PPLogger.shared?.log("Vault creation finished with success")
        return createdVault
    }
}

public struct ShareRepository: ShareRepositoryProtocol {
    public let userData: UserData
    public let localShareDatasource: LocalShareDatasourceProtocol
    public let remoteShareDatasouce: RemoteShareDatasourceProtocol
    public let vaultItemKeysRepository: VaultItemKeysRepositoryProtocol

    public init(userData: UserData,
                localShareDatasource: LocalShareDatasourceProtocol,
                remoteShareDatasouce: RemoteShareDatasourceProtocol,
                vaultItemKeysRepository: VaultItemKeysRepositoryProtocol) {
        self.userData = userData
        self.localShareDatasource = localShareDatasource
        self.remoteShareDatasouce = remoteShareDatasouce
        self.vaultItemKeysRepository = vaultItemKeysRepository
    }

    public init(userData: UserData,
                container: NSPersistentContainer,
                authCredential: AuthCredential,
                apiService: APIService) {
        self.userData = userData
        self.localShareDatasource = LocalShareDatasource(container: container)
        self.remoteShareDatasouce = RemoteShareDatasource(authCredential: authCredential,
                                                          apiService: apiService)
        self.vaultItemKeysRepository = VaultItemKeysRepository(container: container,
                                                               authCredential: authCredential,
                                                               apiService: apiService)
    }
}
