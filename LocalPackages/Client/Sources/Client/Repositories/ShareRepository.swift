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
import Entities
import ProtonCoreLogin
import ProtonCoreNetworking
import ProtonCoreServices

public protocol ShareRepositoryProtocol: Sendable {
    // MARK: - Shares

    /// Get all local shares
    func getShares() async throws -> [SymmetricallyEncryptedShare]

    /// Get all remote shares
    func getRemoteShares(eventStream: VaultSyncEventStream?) async throws -> [Share]

    /// Delete all local shares
    func deleteAllSharesLocally() async throws

    /// Delete locally a given share
    func deleteShareLocally(shareId: String) async throws

    /// Re-encrypt and then upserting shares, emit `decryptedVault` events if `eventStream` is provided
    func upsertShares(_ shares: [Share], eventStream: VaultSyncEventStream?) async throws

    func getUsersLinked(to shareId: String) async throws -> [UserShareInfos]

    func getUserInformations(userId: String, shareId: String) async throws -> UserShareInfos

    @discardableResult
    func updateUserPermission(userId: String,
                              shareId: String,
                              shareRole: ShareRole?,
                              expireTime: Int?) async throws -> Bool
    @discardableResult
    func deleteUserShare(userId: String, shareId: String) async throws -> Bool

    @discardableResult
    func deleteShare(shareId: String) async throws -> Bool

    // MARK: - Vault Functions

    /// Get all local vaults
    func getVaults() async throws -> [Vault]

    /// Get local vault by ID
    func getVault(shareId: String) async throws -> Vault?

    @discardableResult
    func createVault(_ vault: VaultProtobuf) async throws -> Share

    func edit(oldVault: Vault, newVault: VaultProtobuf) async throws

    /// Delete vault. If vault is not empty (0 active & trashed items)  an error is thrown.
    func deleteVault(shareId: String) async throws

    @discardableResult
    func transferVaultOwnership(vaultShareId: String, newOwnerShareId: String) async throws -> Bool
}

public extension ShareRepositoryProtocol {
    func getRemoteShares() async throws -> [Share] {
        try await getRemoteShares(eventStream: nil)
    }

    func upsertShares(_ shares: [Share]) async throws {
        try await upsertShares(shares, eventStream: nil)
    }
}

public actor ShareRepository: ShareRepositoryProtocol {
    public let userDataSymmetricKeyProvider: UserDataSymmetricKeyProvider
    public let localDatasource: LocalShareDatasourceProtocol
    public let remoteDatasouce: RemoteShareDatasourceProtocol
    public let passKeyManager: PassKeyManagerProtocol
    public let logger: Logger

    public init(userDataSymmetricKeyProvider: UserDataSymmetricKeyProvider,
                localDatasource: LocalShareDatasourceProtocol,
                remoteDatasouce: RemoteShareDatasourceProtocol,
                passKeyManager: PassKeyManagerProtocol,
                logManager: LogManagerProtocol) {
        self.userDataSymmetricKeyProvider = userDataSymmetricKeyProvider
        self.localDatasource = localDatasource
        self.remoteDatasouce = remoteDatasouce
        self.passKeyManager = passKeyManager
        logger = .init(manager: logManager)
    }
}

public extension ShareRepository {
    func getShares() async throws -> [SymmetricallyEncryptedShare] {
        let userId = try userDataSymmetricKeyProvider.getUserId()
        logger.trace("Getting all local shares for user \(userId)")
        do {
            let shares = try await localDatasource.getAllShares(userId: userId)
            logger.trace("Got \(shares.count) local shares for user \(userId)")
            return shares
        } catch {
            logger.error(message: "Failed to get local shares for user \(userId)", error: error)
            throw error
        }
    }

    func getRemoteShares(eventStream: VaultSyncEventStream?) async throws -> [Share] {
        let userId = try userDataSymmetricKeyProvider.getUserId()
        logger.trace("Getting all remote shares for user \(userId)")
        do {
            let shares = try await remoteDatasouce.getShares()
            eventStream?.send(.downloadedShares(shares))
            logger.trace("Got \(shares.count) remote shares for user \(userId)")
            return shares
        } catch {
            logger.error(message: "Failed to get remote shares for user \(userId)", error: error)
            throw error
        }
    }

    func deleteAllSharesLocally() async throws {
        let userId = try userDataSymmetricKeyProvider.getUserId()
        logger.trace("Deleting all local shares for user \(userId)")
        try await localDatasource.removeAllShares(userId: userId)
        logger.trace("Deleted all local shares for user \(userId)")
    }

    func deleteShareLocally(shareId: String) async throws {
        let userId = try userDataSymmetricKeyProvider.getUserId()
        logger.trace("Deleting local share \(shareId) for user \(userId)")
        try await localDatasource.removeShare(shareId: shareId, userId: userId)
        logger.trace("Deleted local share \(shareId) for user \(userId)")
    }

    func upsertShares(_ shares: [Share], eventStream: VaultSyncEventStream?) async throws {
        let userId = try userDataSymmetricKeyProvider.getUserId()
        logger.trace("Upserting \(shares.count) shares for user \(userId)")
        let encryptedShares = try await shares
            .parallelMap { [weak self] in
                // swiftlint:disable:next discouraged_optional_self
                try await self?.symmetricallyEncryptNullable($0)
            }
            .compactMap { $0 }
        try await localDatasource.upsertShares(encryptedShares, userId: userId)

        if let eventStream {
            for share in encryptedShares {
                if let vault = try share.toVault(symmetricKey: getSymmetricKey()) {
                    eventStream.send(.decryptedVault(vault))
                }
            }
        }

        logger.trace("Upserted \(shares.count) shares for user \(userId)")
    }

    func getUsersLinked(to shareId: String) async throws -> [UserShareInfos] {
        logger.trace("Getting all users linked to shareId \(shareId)")
        let users = try await remoteDatasouce.getShareLinkedUsers(shareId: shareId)
        logger.trace("Got \(users.count) remote user for \(shareId)")
        return users
    }

    func getUserInformations(userId: String, shareId: String) async throws -> UserShareInfos {
        let logInfo = "user \(userId), share \(shareId)"
        logger.trace("Getting user information \(logInfo)")
        do {
            let user = try await remoteDatasouce.getUserInformationForShare(shareId: shareId, userId: userId)
            logger.trace("Got user information \(logInfo)")
            return user
        } catch {
            logger.error(message: "Failed to get user information \(logInfo)", error: error)
            throw error
        }
    }

    func updateUserPermission(userId: String,
                              shareId: String,
                              shareRole: ShareRole?,
                              expireTime: Int?) async throws -> Bool {
        let logInfo = "permission \(shareRole?.rawValue ?? ""), user \(userId), share \(shareId)"
        logger.trace("Updating \(logInfo)")
        do {
            let request = UserSharePermissionRequest(shareRole: shareRole, expireTime: expireTime)
            let updated = try await remoteDatasouce.updateUserSharePermission(shareId: shareId,
                                                                              userId: userId,
                                                                              request: request)
            logger.trace("Updated \(logInfo)")
            return updated
        } catch {
            logger.error(message: "Failed to update \(logInfo)", error: error)
            throw error
        }
    }

    func deleteUserShare(userId: String, shareId: String) async throws -> Bool {
        let logInfo = "user \(userId), share \(shareId)"
        logger.trace("Deleting user share \(logInfo)")
        do {
            let deleted = try await remoteDatasouce.deleteUserShare(shareId: shareId, userId: userId)
            logger.trace("Deleted \(deleted) user share \(logInfo)")
            return deleted
        } catch {
            logger.error(message: "Failed to delete user share \(logInfo)", error: error)
            throw error
        }
    }

    func deleteShare(shareId: String) async throws -> Bool {
        let logInfo = "share \(shareId)"
        logger.trace("Deleting share \(logInfo)")
        let deleted = try await remoteDatasouce.deleteShare(shareId: shareId)
        logger.trace("Deleted \(deleted) user share \(logInfo)")
        return deleted
    }
}

// MARK: - Vaults

public extension ShareRepository {
    func getVaults() async throws -> [Vault] {
        let userId = try userDataSymmetricKeyProvider.getUserId()
        logger.trace("Getting local vaults for user \(userId)")

        let shares = try await getShares()
        let vaults = try shares.compactMap { try $0.toVault(symmetricKey: getSymmetricKey()) }
        logger.trace("Got \(vaults.count) local vaults for user \(userId)")
        return vaults
    }

    func getVault(shareId: String) async throws -> Vault? {
        let userId = try userDataSymmetricKeyProvider.getUserId()
        logger.trace("Getting local vault with shareID \(shareId) for user \(userId)")
        guard let share = try await localDatasource.getShare(userId: userId, shareId: shareId) else {
            logger.trace("Found no local vault with shareID \(shareId) for user \(userId)")
            return nil
        }
        logger.trace("Got local vault with shareID \(shareId) for user \(userId)")
        return try share.toVault(symmetricKey: getSymmetricKey())
    }

    func createVault(_ vault: VaultProtobuf) async throws -> Share {
        let userData = try userDataSymmetricKeyProvider.getUnwrappedUserData()
        let userId = userData.user.ID
        logger.trace("Creating vault for user \(userId)")
        let request = try CreateVaultRequest(userData: userData, vault: vault)
        let createdVault = try await remoteDatasouce.createVault(request: request)
        let encryptedShare = try await symmetricallyEncrypt(createdVault)
        logger.trace("Saving newly created vault to local for user \(userId)")
        try await localDatasource.upsertShares([encryptedShare], userId: userId)
        logger.trace("Created vault for user \(userId)")
        return createdVault
    }

    func edit(oldVault: Vault, newVault: VaultProtobuf) async throws {
        let userData = try userDataSymmetricKeyProvider.getUnwrappedUserData()
        let userId = userData.user.ID
        logger.trace("Editing vault \(oldVault.id) for user \(userId)")
        let shareId = oldVault.shareId
        let shareKey = try await passKeyManager.getLatestShareKey(shareId: shareId)
        let request = try UpdateVaultRequest(vault: newVault,
                                             shareKey: shareKey,
                                             userData: userData)
        let updatedVault = try await remoteDatasouce.updateVault(request: request, shareId: shareId)
        logger.trace("Saving updated vault \(oldVault.id) to local for user \(userId)")
        let encryptedShare = try await symmetricallyEncrypt(updatedVault)
        try await localDatasource.upsertShares([encryptedShare], userId: userId)
        logger.trace("Updated vault \(oldVault.id) for user \(userId)")
    }

    func deleteVault(shareId: String) async throws {
        let userId = try userDataSymmetricKeyProvider.getUserId()
        // Remote deletion
        logger.trace("Deleting remote vault \(shareId) for user \(userId)")
        try await remoteDatasouce.deleteVault(shareId: shareId)
        logger.trace("Deleted remote vault \(shareId) for user \(userId)")

        // Local deletion
        logger.trace("Deleting local vault \(shareId) for user \(userId)")
        try await localDatasource.removeShare(shareId: shareId, userId: userId)
        logger.trace("Deleted local vault \(shareId) for user \(userId)")

        logger.trace("Finished deleting vault \(shareId) for user \(userId)")
    }

    func transferVaultOwnership(vaultShareId: String, newOwnerShareId: String) async throws -> Bool {
        logger.trace("Setting new owner \(newOwnerShareId) for vault \(vaultShareId)")

        let request = TransferOwnershipVaultRequest(newOwnerShareID: newOwnerShareId)
        let updated = try await remoteDatasouce.transferVaultOwnership(vaultShareId: vaultShareId,
                                                                       request: request)
        logger.info("Finished transfer of ownership")
        return updated
    }
}

private extension ShareRepository {
    func getSymmetricKey() throws -> SymmetricKey {
        try userDataSymmetricKeyProvider.getSymmetricKey()
    }

    func symmetricallyEncrypt(_ share: Share) async throws -> SymmetricallyEncryptedShare {
        guard let content = share.content,
              let keyRotation = share.contentKeyRotation else {
            return .init(encryptedContent: nil, share: share)
        }

        guard let contentData = try content.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        guard contentData.count > 12 else {
            throw PassError.crypto(.corruptedShareContent(shareID: share.shareID))
        }

        let key = try await passKeyManager.getShareKey(shareId: share.shareID,
                                                       keyRotation: keyRotation)
        let decryptedContent = try AES.GCM.open(contentData,
                                                key: key.keyData,
                                                associatedData: .vaultContent)
        let reencryptedContent = try getSymmetricKey().encrypt(decryptedContent.encodeBase64())
        return .init(encryptedContent: reencryptedContent, share: share)
    }

    /// Symmetrically encrypt but return `nil` when encounting inactive user key instead of throwing
    /// We don't want to throw errors and stop the whole decryption process when we find an inactive user key
    func symmetricallyEncryptNullable(_ share: Share) async throws -> SymmetricallyEncryptedShare? {
        do {
            return try await symmetricallyEncrypt(share)
        } catch {
            if let passError = error as? PassError,
               case let .crypto(reason) = passError,
               case .inactiveUserKey = reason {
                // We can’t decrypt old vaults because of password reset
                // just log and move on instead of throwing
                logger.warning(reason.debugDescription)
                return nil
            } else {
                throw error
            }
        }
    }
}

private extension SymmetricallyEncryptedShare {
    func toVault(symmetricKey: SymmetricKey) throws -> Vault? {
        guard share.shareType == .vault, let encryptedContent else { return nil }

        let decryptedContent = try symmetricKey.decrypt(encryptedContent)
        guard let decryptedContentData = try decryptedContent.base64Decode() else { return nil }
        let vaultContent = try VaultProtobuf(data: decryptedContentData)

        return .init(id: share.vaultID,
                     shareId: share.shareID,
                     addressId: share.addressID,
                     name: vaultContent.name,
                     description: vaultContent.description_p,
                     displayPreferences: vaultContent.display,
                     isOwner: share.owner,
                     shareRole: ShareRole(rawValue: share.shareRoleID) ?? .read,
                     members: Int(share.targetMembers),
                     maxMembers: Int(share.targetMaxMembers),
                     pendingInvites: Int(share.pendingInvites),
                     newUserInvitesReady: Int(share.newUserInvitesReady),
                     shared: share.shared,
                     createTime: share.createTime)
    }
}
