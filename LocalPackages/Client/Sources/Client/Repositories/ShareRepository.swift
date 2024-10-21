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

@preconcurrency import Combine
import Core
import CryptoKit
import Entities
import ProtonCoreLogin

// sourcery: AutoMockable
public protocol ShareRepositoryProtocol: Sendable {
    // MARK: - Shares

    /// Get all local shares
    func getShares(userId: String) async throws -> [SymmetricallyEncryptedShare]

    /// Get all remote shares
    func getRemoteShares(userId: String,
                         eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?) async throws -> [Share]

    /// Delete all local shares
    func deleteAllCurrentUserSharesLocally() async throws

    /// Delete locally a given share
    func deleteShareLocally(userId: String, shareId: String) async throws

    /// Re-encrypt and then upserting shares, emit `decryptedVault` events if `eventStream` is provided
    func upsertShares(userId: String,
                      shares: [Share],
                      eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?) async throws

    func getUsersLinked(to shareId: String) async throws -> [UserShareInfos]

//    func getUserInformations(userId: String, shareId: String) async throws -> UserShareInfos

    @discardableResult
    func updateUserPermission(userShareId: String,
                              shareId: String,
                              shareRole: ShareRole?,
                              expireTime: Int?) async throws -> Bool
    @discardableResult
    func deleteUserShare(userShareId: String, shareId: String) async throws -> Bool

    @discardableResult
    func deleteShare(userId: String, shareId: String) async throws -> Bool

    // MARK: - Vault Functions

    /// Get all local vaults
    func getVaults(userId: String) async throws -> [Vault]

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
    func getRemoteShares(userId: String) async throws -> [Share] {
        try await getRemoteShares(userId: userId, eventStream: nil)
    }

    func upsertShares(userId: String, shares: [Share]) async throws {
        try await upsertShares(userId: userId, shares: shares, eventStream: nil)
    }
}

public actor ShareRepository: ShareRepositoryProtocol {
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let userManager: any UserManagerProtocol
    private let localDatasource: any LocalShareDatasourceProtocol
    private let remoteDatasouce: any RemoteShareDatasourceProtocol
    private let passKeyManager: any PassKeyManagerProtocol
    private let logger: Logger

    public init(symmetricKeyProvider: any SymmetricKeyProvider,
                userManager: any UserManagerProtocol,
                localDatasource: any LocalShareDatasourceProtocol,
                remoteDatasouce: any RemoteShareDatasourceProtocol,
                passKeyManager: any PassKeyManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.symmetricKeyProvider = symmetricKeyProvider
        self.localDatasource = localDatasource
        self.remoteDatasouce = remoteDatasouce
        self.passKeyManager = passKeyManager
        logger = .init(manager: logManager)
        self.userManager = userManager
    }
}

public extension ShareRepository {
    func getShares(userId: String) async throws -> [SymmetricallyEncryptedShare] {
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

    func getRemoteShares(userId: String,
                         eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?) async throws
        -> [Share] {
        logger.trace("Getting all remote shares for user \(userId)")
        do {
            let shares = try await remoteDatasouce.getShares(userId: userId)
            eventStream?.send(.downloadedShares(shares))
            logger.trace("Got \(shares.count) remote shares for user \(userId)")
            return shares
        } catch {
            logger.error(message: "Failed to get remote shares for user \(userId)", error: error)
            throw error
        }
    }

    func deleteAllCurrentUserSharesLocally() async throws {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Deleting all local shares for user \(userId)")
        try await localDatasource.removeAllShares(userId: userId)
        logger.trace("Deleted all local shares for user \(userId)")
    }

    func deleteShareLocally(userId: String, shareId: String) async throws {
        logger.trace("Deleting local share \(shareId) for user \(userId)")
        try await localDatasource.removeShare(shareId: shareId, userId: userId)
        logger.trace("Deleted local share \(shareId) for user \(userId)")
    }

    func upsertShares(userId: String,
                      shares: [Share],
                      eventStream: CurrentValueSubject<VaultSyncProgressEvent, Never>?) async throws {
        logger.trace("Upserting \(shares.count) shares for user \(userId)")
        let encryptedShares = try await shares
            .parallelMap { [weak self] in
                // swiftlint:disable:next discouraged_optional_self
                try await self?.symmetricallyEncryptNullable(userId: userId, $0)
            }
            .compactMap { $0 }
        try await localDatasource.upsertShares(encryptedShares, userId: userId)

        if eventStream != nil {
            let symmetricKey = try await getSymmetricKey()
            for share in encryptedShares {
                if let vault = try share.toVault(symmetricKey: symmetricKey) {
                    eventStream?.send(.decryptedVault(vault))
                }
            }
        }

        logger.trace("Upserted \(shares.count) shares for user \(userId)")
    }

    func getUsersLinked(to shareId: String) async throws -> [UserShareInfos] {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Getting all users linked to shareId \(shareId)")
        let users = try await remoteDatasouce.getShareLinkedUsers(userId: userId, shareId: shareId)
        logger.trace("Got \(users.count) remote user for \(shareId)")
        return users
    }

    func updateUserPermission(userShareId: String,
                              shareId: String,
                              shareRole: ShareRole?,
                              expireTime: Int?) async throws -> Bool {
        let userId = try await userManager.getActiveUserId()
        let logInfo = "permission \(shareRole?.rawValue ?? ""), user \(userId), share \(shareId)"
        logger.trace("Updating \(logInfo)")
        do {
            let request = UserSharePermissionRequest(shareRole: shareRole, expireTime: expireTime)
            let updated = try await remoteDatasouce.updateUserSharePermission(userId: userId,
                                                                              shareId: shareId,
                                                                              userShareId: userShareId,
                                                                              request: request)
            logger.trace("Updated \(logInfo)")
            return updated
        } catch {
            logger.error(message: "Failed to update \(logInfo)", error: error)
            throw error
        }
    }

    func deleteUserShare(userShareId: String, shareId: String) async throws -> Bool {
        let userId = try await userManager.getActiveUserId()
        let logInfo = "user \(userId), share \(shareId)"
        logger.trace("Deleting user share \(logInfo)")
        do {
            let deleted = try await remoteDatasouce.deleteUserShare(userId: userId,
                                                                    shareId: shareId,
                                                                    userShareId: userShareId)
            logger.trace("Deleted \(deleted) user share \(logInfo)")
            return deleted
        } catch {
            logger.error(message: "Failed to delete user share \(logInfo)", error: error)
            throw error
        }
    }

    func deleteShare(userId: String, shareId: String) async throws -> Bool {
        let logInfo = "share \(shareId)"
        logger.trace("Deleting share \(logInfo)")
        let deleted = try await remoteDatasouce.deleteShare(userId: userId, shareId: shareId)
        logger.trace("Deleted \(deleted) user share \(logInfo)")
        return deleted
    }
}

// MARK: - Vaults

public extension ShareRepository {
    func getVaults(userId: String) async throws -> [Vault] {
        logger.trace("Getting local vaults for user \(userId)")

        let shares = try await getShares(userId: userId)
        let symmetricKey = try await getSymmetricKey()
        let vaults = try shares.compactMap { try $0.toVault(symmetricKey: symmetricKey) }
        logger.trace("Got \(vaults.count) local vaults for user \(userId)")
        return vaults
    }

    func getVault(shareId: String) async throws -> Vault? {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Getting local vault with shareID \(shareId) for user \(userId)")
        guard let share = try await localDatasource.getShare(userId: userId, shareId: shareId) else {
            logger.trace("Found no local vault with shareID \(shareId) for user \(userId)")
            return nil
        }
        logger.trace("Got local vault with shareID \(shareId) for user \(userId)")
        return try await share.toVault(symmetricKey: getSymmetricKey())
    }

    func createVault(_ vault: VaultProtobuf) async throws -> Share {
        let userData = try await userManager.getUnwrappedActiveUserData()
        let userId = userData.user.ID
        logger.trace("Creating vault for user \(userId)")
        let request = try CreateVaultRequest(userData: userData, vault: vault)
        let createdVault = try await remoteDatasouce.createVault(userId: userId, request: request)
        let encryptedShare = try await symmetricallyEncrypt(userId: userId, createdVault)
        logger.trace("Saving newly created vault to local for user \(userId)")
        try await localDatasource.upsertShares([encryptedShare], userId: userId)
        logger.trace("Created vault for user \(userId)")
        return createdVault
    }

    func edit(oldVault: Vault, newVault: VaultProtobuf) async throws {
        let userData = try await userManager.getUnwrappedActiveUserData()
        let userId = userData.user.ID
        logger.trace("Editing vault \(oldVault.id) for user \(userId)")
        let shareId = oldVault.shareId
        let shareKey = try await passKeyManager.getLatestShareKey(userId: userId, shareId: shareId)
        let request = try UpdateVaultRequest(vault: newVault, shareKey: shareKey)
        let updatedVault = try await remoteDatasouce.updateVault(userId: userId,
                                                                 request: request,
                                                                 shareId: shareId)
        logger.trace("Saving updated vault \(oldVault.id) to local for user \(userId)")
        let encryptedShare = try await symmetricallyEncrypt(userId: userId, updatedVault)
        try await localDatasource.upsertShares([encryptedShare], userId: userId)
        logger.trace("Updated vault \(oldVault.id) for user \(userId)")
    }

    func deleteVault(shareId: String) async throws {
        let userId = try await userManager.getActiveUserId()
        // Remote deletion
        logger.trace("Deleting remote vault \(shareId) for user \(userId)")
        try await remoteDatasouce.deleteVault(userId: userId, shareId: shareId)
        logger.trace("Deleted remote vault \(shareId) for user \(userId)")

        // Local deletion
        logger.trace("Deleting local vault \(shareId) for user \(userId)")
        try await localDatasource.removeShare(shareId: shareId, userId: userId)
        logger.trace("Deleted local vault \(shareId) for user \(userId)")

        logger.trace("Finished deleting vault \(shareId) for user \(userId)")
    }

    func transferVaultOwnership(vaultShareId: String, newOwnerShareId: String) async throws -> Bool {
        logger.trace("Setting new owner \(newOwnerShareId) for vault \(vaultShareId)")
        let userId = try await userManager.getActiveUserId()
        let request = TransferOwnershipVaultRequest(newOwnerShareID: newOwnerShareId)
        let updated = try await remoteDatasouce.transferVaultOwnership(userId: userId,
                                                                       vaultShareId: vaultShareId,
                                                                       request: request)
        logger.info("Finished transfer of ownership")
        return updated
    }
}

private extension ShareRepository {
    func getSymmetricKey() async throws -> SymmetricKey {
        try await symmetricKeyProvider.getSymmetricKey()
    }

    func symmetricallyEncrypt(userId: String, _ share: Share) async throws -> SymmetricallyEncryptedShare {
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

        let key = try await passKeyManager.getShareKey(userId: userId,
                                                       shareId: share.shareID,
                                                       keyRotation: keyRotation)
        let decryptedContent = try AES.GCM.open(contentData,
                                                key: key.keyData,
                                                associatedData: .vaultContent)
        let reencryptedContent = try await getSymmetricKey().encrypt(decryptedContent.encodeBase64())
        return .init(encryptedContent: reencryptedContent, share: share)
    }

    /// Symmetrically encrypt but return `nil` when encounting inactive user key instead of throwing
    /// We don't want to throw errors and stop the whole decryption process when we find an inactive user key
    @Sendable func symmetricallyEncryptNullable(userId: String,
                                                _ share: Share) async throws -> SymmetricallyEncryptedShare? {
        do {
            return try await symmetricallyEncrypt(userId: userId, share)
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

        return Vault(id: share.vaultID,
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
                     createTime: share.createTime,
                     canAutoFill: share.canAutoFill)
    }
}
