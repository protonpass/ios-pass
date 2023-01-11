//
// VaultItemKeysRepository.swift
// Proton Pass - Created on 24/09/2022.
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
import ProtonCore_Networking
import ProtonCore_Services

public enum VaultItemKeysRepositoryError: Error {
    case noVaultKey(shareId: String)
    case noItemKey(shareId: String, rotationId: String)
}

/// This repository is not offline first because without keys, the app is not functional.
public protocol VaultItemKeysRepositoryProtocol {
    var localItemKeyDatasource: LocalItemKeyDatasourceProtocol { get }
    var localVaultKeyDatasource: LocalVaultKeyDatasourceProtocol { get }
    var remoteVaultItemKeysDatasource: RemoteVaultItemKeysDatasourceProtocol { get }
    var logger: Logger { get }

    /// Get the pair of vaul key & item key that have latest `rotation`. Not offline first.
    func getLatestVaultItemKeys(shareId: String) async throws -> VaultItemKeys

    /// Get vault keys of a share with `shareId`. Not offline first.
    func getVaultKeys(shareId: String) async throws -> [VaultKey]

    /// Get item keys of a share with `shareId`. Not offline first.
    func getItemKeys(shareId: String) async throws -> [ItemKey]

    /// Refresh vault & item keys of a share with `shareId`
    @discardableResult
    func refreshVaultItemKeys(shareId: String) async throws -> ([VaultKey], [ItemKey])
}

public extension VaultItemKeysRepositoryProtocol {
    func getLatestVaultItemKeys(shareId: String) async throws -> VaultItemKeys {
        logger.trace("Getting vault & item keys for share \(shareId)")

        let vaultKeys = try await localVaultKeyDatasource.getVaultKeys(shareId: shareId)
        if vaultKeys.isEmpty {
            logger.trace("No local vault keys for share \(shareId). Fetching from remote.")
            try await refreshVaultItemKeys(shareId: shareId)
        }

        let itemKeys = try await localItemKeyDatasource.getItemKeys(shareId: shareId)
        if itemKeys.isEmpty {
            logger.trace("No local item keys for share \(shareId). Fetching from remote.")
            try await refreshVaultItemKeys(shareId: shareId)
        }

        guard let latestVaultKey = vaultKeys.max(by: { $0.rotation < $1.rotation }) else {
            logger.fatal("No vault keys for share \(shareId)")
            throw VaultItemKeysRepositoryError.noVaultKey(shareId: shareId)
        }

        guard let latestItemKey = itemKeys.first(where: { $0.rotationID == latestVaultKey.rotationID }) else {
            logger.fatal("No item keys with roration \(latestVaultKey.rotationID) of share \(shareId)")
            throw VaultItemKeysRepositoryError.noItemKey(shareId: shareId, rotationId: latestVaultKey.rotationID)
        }

        logger.trace("Got vault & item keys for share \(shareId)")
        return try .init(vaultKey: latestVaultKey, itemKey: latestItemKey)
    }

    func getVaultKeys(shareId: String) async throws -> [VaultKey] {
        logger.trace("Getting vault keys for share \(shareId)")
        let vaultKeys = try await localVaultKeyDatasource.getVaultKeys(shareId: shareId)
        if vaultKeys.isEmpty {
            logger.trace("No local vault keys for share \(shareId). Fetching from remote.")
            let (vaultKeys, _) = try await refreshVaultItemKeys(shareId: shareId)
            logger.trace("Got vault keys for share \(shareId) after refreshing.")
            return vaultKeys
        }

        logger.trace("Got local vault keys for share \(shareId)")
        return vaultKeys
    }

    func getItemKeys(shareId: String) async throws -> [ItemKey] {
        logger.trace("Getting item keys for share \(shareId)")
        let itemKeys = try await localItemKeyDatasource.getItemKeys(shareId: shareId)
        if itemKeys.isEmpty {
            logger.trace("No local item keys for share \(shareId). Fetching from remote.")
            let (_, itemKeys) = try await refreshVaultItemKeys(shareId: shareId)
            logger.trace("Got item keys for share \(shareId) after refreshing.")
            return itemKeys
        }

        logger.trace("Got local item keys for share \(shareId)")
        return itemKeys
    }

    func refreshVaultItemKeys(shareId: String) async throws -> ([VaultKey], [ItemKey]) {
        logger.trace("Refreshing vault & item keys for share \(shareId)")
        let (vaultKeys, itemKeys) = try await remoteVaultItemKeysDatasource.getVaultItemKeys(shareId: shareId)
        logger.trace("Got from remote \(vaultKeys.count) vault keys, \(itemKeys.count) item keys share \(shareId)")

        logger.trace("Saving \(vaultKeys.count) vault keys to local database for share \(shareId)")
        try await localVaultKeyDatasource.upsertVaultKeys(vaultKeys, shareId: shareId)
        logger.trace("Saved \(vaultKeys.count) vault keys to local database for share \(shareId)")

        logger.trace("Saving \(itemKeys.count) item keys to local database for share \(shareId)")
        try await localItemKeyDatasource.upsertItemKeys(itemKeys, shareId: shareId)
        logger.trace("Saved \(itemKeys.count) item keys to local database for share \(shareId)")
        logger.trace("Refreshed vault & item keys for share \(shareId)")
        return (vaultKeys, itemKeys)
    }
}

public final class VaultItemKeysRepository: VaultItemKeysRepositoryProtocol {
    public let localItemKeyDatasource: LocalItemKeyDatasourceProtocol
    public let localVaultKeyDatasource: LocalVaultKeyDatasourceProtocol
    public let remoteVaultItemKeysDatasource: RemoteVaultItemKeysDatasourceProtocol
    public let logger: Logger

    public init(localItemKeyDatasource: LocalItemKeyDatasourceProtocol,
                localVaultKeyDatasource: LocalVaultKeyDatasourceProtocol,
                remoteVaultItemKeysDatasource: RemoteVaultItemKeysDatasourceProtocol,
                logManager: LogManager) {
        self.localItemKeyDatasource = localItemKeyDatasource
        self.localVaultKeyDatasource = localVaultKeyDatasource
        self.remoteVaultItemKeysDatasource = remoteVaultItemKeysDatasource
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }

    public init(container: NSPersistentContainer,
                authCredential: AuthCredential,
                apiService: APIService,
                logManager: LogManager) {
        self.localItemKeyDatasource = LocalItemKeyDatasource(container: container)
        self.localVaultKeyDatasource = LocalVaultKeyDatasource(container: container)
        self.remoteVaultItemKeysDatasource = RemoteVaultItemKeysDatasource(authCredential: authCredential,
                                                                           apiService: apiService)
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }
}
