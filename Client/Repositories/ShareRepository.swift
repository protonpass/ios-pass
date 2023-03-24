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
    var passKeyManager: PassKeyManagerProtocol { get }
    var logger: Logger { get }

    /// Get all local shares
    func getShares() async throws -> [Share]

    /// Get all remote shares
    func getRemoteShares() async throws -> [Share]

    /// Get local share with `shareId`
    func getShare(shareId: String) async throws -> Share

    /// Get all local vaults
    func getVaults() async throws -> [Vault]

    /// Delete all local shares
    func deleteAllShares() async throws

    func upsertShares(_ shares: [Share]) async throws

    func createVault(_ vault: VaultProtobuf) async throws

    /// Delete vault. If vault is not empty (0 active & trashed items)  an error is thrown.
    func deleteVault(shareId: String) async throws
}

private extension ShareRepositoryProtocol {
    var userId: String { userData.user.ID }
}

public extension ShareRepositoryProtocol {
    func getShares() async throws -> [Share] {
        logger.trace("Getting all local shares for user \(userId)")
        do {
            let shares = try await localShareDatasource.getAllShares(userId: userId)
            logger.trace("Got \(shares.count) local shares for user \(userId)")
            return shares
        } catch {
            logger.debug("Failed to get local shares for user \(userId). \(String(describing: error))")
            throw error
        }
    }

    func getRemoteShares() async throws -> [Share] {
        logger.trace("Getting all remote shares for user \(userId)")
        do {
            let shares = try await remoteShareDatasouce.getShares()
            logger.trace("Got \(shares.count) remote shares for user \(userId)")
            return shares
        } catch {
            logger.debug("Failed to get remote shares for user \(userId). \(String(describing: error))")
            throw error
        }
    }

    func getShare(shareId: String) async throws -> Share {
        logger.trace("Getting local share \(shareId) of user \(userId)")
        if let share = try await localShareDatasource.getShare(userId: userId, shareId: shareId) {
            logger.trace("Got local share \(shareId) of user \(userId)")
            return share
        }
        logger.debug("No local share found \(shareId) of user \(userId)")
        throw PPClientError.shareNotFoundInLocalDB(shareID: shareId)
    }

    func getVaults() async throws -> [Vault] {
        logger.trace("Getting local vaults for user \(userId)")
        let shares = try await getShares()

        var vaults: [Vault] = []
        for share in shares where share.shareType == .vault {
            let key = try await self.passKeyManager.getShareKey(
                shareId: share.shareID,
                keyRotation: share.contentKeyRotation ?? -1)
            let shareContent = try share.getShareContent(key: key.value)
            switch shareContent {
            case .vault(let vault):
                vaults.append(vault)
            default:
                break
            }
        }
        logger.trace("Got \(vaults.count) local vaults for user \(userId)")
        return vaults
    }

    func deleteAllShares() async throws {
        logger.trace("Deleting all local shares for user \(userId)")
        try await localShareDatasource.removeAllShares(userId: userId)
        logger.trace("Deleted all local shares for user \(userId)")
    }

    func upsertShares(_ shares: [Share]) async throws {
        logger.trace("Upserting \(shares.count) shares for user \(userId)")
        try await localShareDatasource.upsertShares(shares, userId: userId)
        logger.trace("Upserted \(shares.count) shares for user \(userId)")
    }

    func createVault(_ vault: VaultProtobuf) async throws {
        logger.trace("Creating vault for user \(userId)")
        let request = try CreateVaultRequest(userData: userData, vault: vault)
        let createdVault = try await remoteShareDatasouce.createVault(request: request)
        logger.trace("Saving newly created vault to local for user \(userId)")
        try await localShareDatasource.upsertShares([createdVault], userId: userId)
        logger.trace("Created vault for user \(userId)")
    }

    func deleteVault(shareId: String) async throws {
        // Remote deletion
        logger.trace("Deleting remote vault \(shareId) for user \(userId)")
        try await remoteShareDatasouce.deleteVault(shareId: shareId)
        logger.trace("Deleted remote vault \(shareId) for user \(userId)")

        // Local deletion
        logger.trace("Deleting local vault \(shareId) for user \(userId)")
        try await localShareDatasource.removeShare(shareId: shareId, userId: userId)
        logger.trace("Deleted local vault \(shareId) for user \(userId)")

        logger.trace("Finished deleting vault \(shareId) for user \(userId)")
    }
}

public struct ShareRepository: ShareRepositoryProtocol {
    public let userData: UserData
    public let localShareDatasource: LocalShareDatasourceProtocol
    public let remoteShareDatasouce: RemoteShareDatasourceProtocol
    public let passKeyManager: PassKeyManagerProtocol
    public let logger: Logger

    public init(userData: UserData,
                localShareDatasource: LocalShareDatasourceProtocol,
                remoteShareDatasouce: RemoteShareDatasourceProtocol,
                passKeyManager: PassKeyManagerProtocol,
                logManager: LogManager) {
        self.userData = userData
        self.localShareDatasource = localShareDatasource
        self.remoteShareDatasouce = remoteShareDatasouce
        self.passKeyManager = passKeyManager
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }

    public init(userData: UserData,
                container: NSPersistentContainer,
                authCredential: AuthCredential,
                apiService: APIService,
                logManager: LogManager) {
        self.userData = userData
        self.localShareDatasource = LocalShareDatasource(container: container)
        self.remoteShareDatasouce = RemoteShareDatasource(authCredential: authCredential,
                                                          apiService: apiService)
        let shareKeyRepository = ShareKeyRepository(container: container,
                                                    authCredential: authCredential,
                                                    apiService: apiService,
                                                    logManager: logManager)
        let itemKeyDatasource = RemoteItemKeyDatasource(authCredential: authCredential,
                                                        apiService: apiService)
        self.passKeyManager = PassKeyManager(userData: userData,
                                             shareKeyRepository: shareKeyRepository,
                                             itemKeyDatasource: itemKeyDatasource,
                                             logManager: logManager)
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }
}
