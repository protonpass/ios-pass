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

public enum VaultItemKeysRepositoryError: Error {
    case noVaultKey(shareId: String)
    case noItemKey(shareId: String, rotationId: String)
}

public protocol VaultItemKeysRepositoryProtocol {
    var localItemKeyDatasource: LocalItemKeyDatasourceProtocolV2 { get }
    var localVaultKeyDatasource: LocalVaultKeyDatasourceProtocolV2 { get }
    var remoteVaultItemKeysDatasource: RemoteVaultItemKeysDatasourceProtocol { get }

    /// Get the pair of vaul key & item key that have latest `rotation`
    func getLatestVaultItemKeys(shareId: String, forceRefresh: Bool) async throws -> VaultItemKeys

    /// Get vault keys of a share
    func getVaultKeys(shareId: String, forceRefresh: Bool) async throws -> [VaultKey]
}

public extension VaultItemKeysRepositoryProtocol {
    func getLatestVaultItemKeys(shareId: String, forceRefresh: Bool) async throws -> VaultItemKeys {
        PPLogger.shared?.log("Getting vault & item keys for share \(shareId)")
        if forceRefresh {
            PPLogger.shared?.log("Force refresh vault & item keys for share \(shareId)")
            try await refreshVaultItemKeys(shareId: shareId)
        }

        let vaultKeys = try await localVaultKeyDatasource.getVaultKeys(shareId: shareId)
        if vaultKeys.isEmpty {
            PPLogger.shared?.log("No vault key in local database for share \(shareId) => Fetch from remote")
            try await refreshVaultItemKeys(shareId: shareId)
        }

        let itemKeys = try await localItemKeyDatasource.getItemKeys(shareId: shareId)
        if itemKeys.isEmpty {
            PPLogger.shared?.log("No item key in local database for share \(shareId) => Fetch from remote")
            try await refreshVaultItemKeys(shareId: shareId)
        }

        guard let latestVaultKey = vaultKeys.max(by: { $0.rotation < $1.rotation }) else {
            throw VaultItemKeysRepositoryError.noVaultKey(shareId: shareId)
        }

        guard let latestItemKey = itemKeys.first(where: { $0.rotationID == latestVaultKey.rotationID }) else {
            throw VaultItemKeysRepositoryError.noItemKey(shareId: shareId, rotationId: latestVaultKey.rotationID)
        }

        return try .init(vaultKey: latestVaultKey, itemKey: latestItemKey)
    }

    func getVaultKeys(shareId: String, forceRefresh: Bool) async throws -> [VaultKey] {
        if forceRefresh {
            try await refreshVaultItemKeys(shareId: shareId)
        }

        let vaultKeys = try await localVaultKeyDatasource.getVaultKeys(shareId: shareId)
        if vaultKeys.isEmpty {
            try await refreshVaultItemKeys(shareId: shareId)
        }

        return try await localVaultKeyDatasource.getVaultKeys(shareId: shareId)
    }

    private func refreshVaultItemKeys(shareId: String) async throws {
        PPLogger.shared?.log("Getting vault & item keys from remote")
        let (vaultKeys, itemKeys) = try await remoteVaultItemKeysDatasource.getVaultItemKeys(shareId: shareId)
        PPLogger.shared?.log("Got \(vaultKeys.count) vault keys & \(itemKeys.count) item keys from remote")

        PPLogger.shared?.log("Saving \(vaultKeys.count) vault keys local database")
        try await localVaultKeyDatasource.upsertVaultKeys(vaultKeys, shareId: shareId)
        PPLogger.shared?.log("Saved \(vaultKeys.count) vault keys to local database")

        PPLogger.shared?.log("Saving \(itemKeys.count) item keys local database")
        try await localItemKeyDatasource.upsertItemKeys(itemKeys, shareId: shareId)
        PPLogger.shared?.log("Saved \(itemKeys.count) item keys to local database")
    }
}

public final class VaultItemKeysRepository: VaultItemKeysRepositoryProtocol {
    public let localItemKeyDatasource: LocalItemKeyDatasourceProtocolV2
    public let localVaultKeyDatasource: LocalVaultKeyDatasourceProtocolV2
    public let remoteVaultItemKeysDatasource: RemoteVaultItemKeysDatasourceProtocol

    public init(localItemKeyDatasource: LocalItemKeyDatasourceProtocolV2,
                localVaultKeyDatasource: LocalVaultKeyDatasourceProtocolV2,
                remoteVaultItemKeysDatasource: RemoteVaultItemKeysDatasourceProtocol) {
        self.localItemKeyDatasource = localItemKeyDatasource
        self.localVaultKeyDatasource = localVaultKeyDatasource
        self.remoteVaultItemKeysDatasource = remoteVaultItemKeysDatasource
    }
}
