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
import CryptoKit
import ProtonCore_Login
import ProtonCore_Networking
import ProtonCore_Services

public protocol ShareRepositoryProtocol {
    var symmetricKey: SymmetricKey { get }
    var userData: UserData { get }
    var localShareDatasource: LocalShareDatasourceProtocol { get }
    var remoteShareDatasouce: RemoteShareDatasourceProtocol { get }
    var passKeyManager: PassKeyManagerProtocol { get }
    var logger: Logger { get }

    /// Get all local shares
    func getShares() async throws -> [SymmetricallyEncryptedShare]

    /// Get all remote shares
    func getRemoteShares() async throws -> [Share]

    /// Get all local vaults
    func getVaults() async throws -> [Vault]

    /// Delete all local shares
    func deleteAllSharesLocally() async throws

    /// Delete locally a given share
    func deleteShareLocally(shareId: String) async throws

    func upsertShares(_ shares: [Share]) async throws

    @discardableResult
    func createVault(_ vault: VaultProtobuf) async throws -> Share

    func edit(oldVault: Vault, newVault: VaultProtobuf) async throws

    /// Delete vault. If vault is not empty (0 active & trashed items)  an error is thrown.
    func deleteVault(shareId: String) async throws

    func setPrimaryVault(shareId: String) async throws -> Bool
}

private extension ShareRepositoryProtocol {
    var userId: String { userData.user.ID }
}

public extension ShareRepositoryProtocol {
    func getShares() async throws -> [SymmetricallyEncryptedShare] {
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

    func getVaults() async throws -> [Vault] {
        logger.trace("Getting local vaults for user \(userId)")

        let shares = try await getShares()
        let vaults = try shares.compactMap { share -> Vault? in
            guard share.share.shareType == .vault else { return nil }

            guard let encryptedContent = share.encryptedContent else { return nil }
            let decryptedContent = try symmetricKey.decrypt(encryptedContent)
            guard let decryptedContentData = try decryptedContent.base64Decode() else { return nil }
            let vaultContent = try VaultProtobuf(data: decryptedContentData)

            return .init(id: share.share.vaultID,
                         shareId: share.share.shareID,
                         name: vaultContent.name,
                         description: vaultContent.description_p,
                         displayPreferences: vaultContent.display,
                         isPrimary: share.share.primary)
        }
        logger.trace("Got \(vaults.count) local vaults for user \(userId)")
        return vaults
    }

    func deleteAllSharesLocally() async throws {
        logger.trace("Deleting all local shares for user \(userId)")
        try await localShareDatasource.removeAllShares(userId: userId)
        logger.trace("Deleted all local shares for user \(userId)")
    }

    func deleteShareLocally(shareId: String) async throws {
        logger.trace("Deleting local share \(shareId) for user \(userId)")
        try await localShareDatasource.removeShare(shareId: shareId, userId: userId)
        logger.trace("Deleted local share \(shareId) for user \(userId)")
    }

    func upsertShares(_ shares: [Share]) async throws {
        logger.trace("Upserting \(shares.count) shares for user \(userId)")
        let encryptedShares = try await shares.parallelMap { try await symmetricallyEncrypt($0) }
        try await localShareDatasource.upsertShares(encryptedShares, userId: userId)
        logger.trace("Upserted \(shares.count) shares for user \(userId)")
    }

    func createVault(_ vault: VaultProtobuf) async throws -> Share {
        logger.trace("Creating vault for user \(userId)")
        let request = try CreateVaultRequest(userData: userData, vault: vault)
        let createdVault = try await remoteShareDatasouce.createVault(request: request)
        let encryptedShare = try await symmetricallyEncrypt(createdVault)
        logger.trace("Saving newly created vault to local for user \(userId)")
        try await localShareDatasource.upsertShares([encryptedShare], userId: userId)
        logger.trace("Created vault for user \(userId)")
        return createdVault
    }

    func edit(oldVault: Vault, newVault: VaultProtobuf) async throws {
        logger.trace("Editing vault \(oldVault.id) for user \(userId)")
        let shareId = oldVault.shareId
        let shareKey = try await passKeyManager.getLatestShareKey(shareId: shareId)
        let request = try UpdateVaultRequest(vault: newVault,
                                             shareKey: shareKey,
                                             userData: userData)
        let updatedVault = try await remoteShareDatasouce.updateVault(request: request, shareId: shareId)
        logger.trace("Saving updated vault \(oldVault.id) to local for user \(userId)")
        let encryptedShare = try await symmetricallyEncrypt(updatedVault)
        try await localShareDatasource.upsertShares([encryptedShare], userId: userId)
        logger.trace("Updated vault \(oldVault.id) for user \(userId)")
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

    func setPrimaryVault(shareId: String) async throws -> Bool {
        logger.trace("Setting primary vault \(shareId) \(shareId) for user \(userId)")
        let shares = try await getShares()
        guard try await remoteShareDatasouce.setPrimaryVault(shareId: shareId) else {
            logger.trace("Failed to set primary vault \(shareId) \(shareId) for user \(userId)")
            return false
        }

        let updatedShares = shares.map { share in
            let clonedShare = share.share.clone(isPrimary: share.share.shareID == shareId)
            return SymmetricallyEncryptedShare(encryptedContent: share.encryptedContent,
                                               share: clonedShare)
        }

        let primaryShares = updatedShares.filter(\.share.primary)
        assert(primaryShares.count == 1, "Should only have one primary vault")
        assert(primaryShares.first?.share.shareID == shareId)

        // Remove all shares before upserting because of CoreData bug
        // that doesn't update boolean values ("primary" boolean of ShareEntity in this case)
        try await localShareDatasource.removeAllShares(userId: userId)
        try await localShareDatasource.upsertShares(updatedShares, userId: userId)
        logger.trace("Finished setting primary vault \(shareId) \(shareId) for user \(userId)")
        return true
    }
}

private extension ShareRepositoryProtocol {
    func symmetricallyEncrypt(_ share: Share) async throws -> SymmetricallyEncryptedShare {
        guard let content = share.content,
              let keyRotation = share.contentKeyRotation else {
            return .init(encryptedContent: nil, share: share)
        }

        guard let contentData = try content.base64Decode() else {
            throw PPClientError.crypto(.failedToBase64Decode)
        }

        guard contentData.count > 12 else {
            throw PPClientError.crypto(.corruptedShareContent(shareID: share.shareID))
        }

        let key = try await passKeyManager.getShareKey(shareId: share.shareID,
                                                       keyRotation: keyRotation)
        let decryptedContent = try AES.GCM.open(contentData,
                                                key: key.keyData,
                                                associatedData: .vaultContent)
        let reencryptedContent = try symmetricKey.encrypt(decryptedContent.encodeBase64())
        return .init(encryptedContent: reencryptedContent, share: share)
    }
}

public struct ShareRepository: ShareRepositoryProtocol {
    public let symmetricKey: SymmetricKey
    public let userData: UserData
    public let localShareDatasource: LocalShareDatasourceProtocol
    public let remoteShareDatasouce: RemoteShareDatasourceProtocol
    public let passKeyManager: PassKeyManagerProtocol
    public let logger: Logger

    public init(symmetricKey: SymmetricKey,
                userData: UserData,
                localShareDatasource: LocalShareDatasourceProtocol,
                remoteShareDatasouce: RemoteShareDatasourceProtocol,
                passKeyManager: PassKeyManagerProtocol,
                logManager: LogManager) {
        self.symmetricKey = symmetricKey
        self.userData = userData
        self.localShareDatasource = localShareDatasource
        self.remoteShareDatasouce = remoteShareDatasouce
        self.passKeyManager = passKeyManager
        logger = .init(manager: logManager)
    }

    public init(symmetricKey: SymmetricKey,
                userData: UserData,
                container: NSPersistentContainer,
                apiService: APIService,
                logManager: LogManager) {
        self.symmetricKey = symmetricKey
        self.userData = userData
        localShareDatasource = LocalShareDatasource(container: container)
        remoteShareDatasouce = RemoteShareDatasource(apiService: apiService)
        let shareKeyRepository = ShareKeyRepository(container: container,
                                                    apiService: apiService,
                                                    logManager: logManager,
                                                    symmetricKey: symmetricKey,
                                                    userData: userData)
        let itemKeyDatasource = RemoteItemKeyDatasource(apiService: apiService)
        passKeyManager = PassKeyManager(shareKeyRepository: shareKeyRepository,
                                        itemKeyDatasource: itemKeyDatasource,
                                        logManager: logManager,
                                        symmetricKey: symmetricKey)
        logger = .init(manager: logManager)
    }
}
