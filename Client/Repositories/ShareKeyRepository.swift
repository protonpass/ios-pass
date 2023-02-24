//
// ShareKeyRepository.swift
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

/// This repository is not offline first because without keys, the app is not functional.
public protocol ShareKeyRepositoryProtocol {
    var localShareKeyDatasource: LocalShareKeyDatasourceProtocol { get }
    var remoteShareKeyDatasource: RemoteShareKeyDatasourceProtocol { get }
    var logger: Logger { get }

    /// Get the share key with latest `rotation`. Not offline first.
    func getLatestKey(shareId: String) async throws -> PassKey

    /// Get share keys of a share with `shareId`. Not offline first.
    func getKeys(shareId: String) async throws -> [PassKey]

    /// Refresh share keys of a share with `shareId`
    @discardableResult
    func refreshKeys(shareId: String) async throws -> [PassKey]
}

public extension ShareKeyRepositoryProtocol {
    func getLatestKey(shareId: String) async throws -> PassKey {
        logger.trace("Getting latest key for share \(shareId)")

        let keys = try await localShareKeyDatasource.getKeys(shareId: shareId)
        if keys.isEmpty {
            logger.trace("No local keys for share \(shareId). Fetching from remote.")
            try await refreshKeys(shareId: shareId)
        }

        guard let latestKey = keys.max(by: { $0.keyRotation < $1.keyRotation }) else {
            logger.fatal("No keys for share \(shareId)")
            throw PPClientError.keysNotFound(shareID: shareId)
        }

        logger.trace("Got latest key for share \(shareId)")
        return latestKey
    }

    func getKeys(shareId: String) async throws -> [PassKey] {
        logger.trace("Getting keys for share \(shareId)")
        let keys = try await localShareKeyDatasource.getKeys(shareId: shareId)
        if keys.isEmpty {
            logger.trace("No local keys for share \(shareId). Fetching from remote.")
            let keys = try await refreshKeys(shareId: shareId)
            logger.trace("Got \(keys.count) keys for share \(shareId) after refreshing.")
            return keys
        }

        logger.trace("Got \(keys.count) local keys for share \(shareId)")
        return keys
    }

    func refreshKeys(shareId: String) async throws -> [PassKey] {
        logger.trace("Refreshing keys for share \(shareId)")
        let keys = try await remoteShareKeyDatasource.getKeys(shareId: shareId)
        logger.trace("Got \(keys.count) keys from remote for share \(shareId)")

        try await localShareKeyDatasource.upsertKeys(keys, shareId: shareId)
        logger.trace("Saved \(keys.count) keys to local database for share \(shareId)")

        logger.trace("Refreshed keys for share \(shareId)")
        return keys
    }
}

public final class ShareKeyRepository: ShareKeyRepositoryProtocol {
    public let localShareKeyDatasource: LocalShareKeyDatasourceProtocol
    public let remoteShareKeyDatasource: RemoteShareKeyDatasourceProtocol
    public let logger: Logger

    public init(localShareKeyDatasource: LocalShareKeyDatasourceProtocol,
                remoteShareKeyDatasource: RemoteShareKeyDatasourceProtocol,
                logManager: LogManager) {
        self.localShareKeyDatasource = localShareKeyDatasource
        self.remoteShareKeyDatasource = remoteShareKeyDatasource
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }

    public init(container: NSPersistentContainer,
                authCredential: AuthCredential,
                apiService: APIService,
                logManager: LogManager) {
        self.localShareKeyDatasource = LocalShareKeyDatasource(container: container)
        self.remoteShareKeyDatasource = RemoteShareKeyDatasource(authCredential: authCredential,
                                                                 apiService: apiService)
        self.logger = .init(subsystem: Bundle.main.bundleIdentifier ?? "",
                            category: "\(Self.self)",
                            manager: logManager)
    }
}
