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
@preconcurrency import CryptoKit
import Entities
import Foundation
@preconcurrency import ProtonCoreLogin

// sourcery: AutoMockable
public protocol ShareRepositoryProtocol: Sendable {
    // MARK: - Shares

    /// Get all local shares
    func getShares(userId: String) async throws -> [SymmetricallyEncryptedShare]
    func getShare(shareId: String) async throws -> Share?
    func getDecryptedShares(userId: String) async throws -> [Share]
    func getDecryptedShare(shareId: String) async throws -> Share?

    /// Get all remote shares and decrypts the content of vault and fills up the vaultcontent of the shares if
    /// possible
    func getDecryptedRemoteShares(userId: String) async throws -> [Share]

    /// Delete all local shares
    func deleteAllCurrentUserSharesLocally() async throws

    /// Delete locally a given share
    func deleteShareLocally(userId: String, shareId: String) async throws

    /// Re-encrypt and then upserting shares, emit `decryptedVault` events if `eventStream` is provided
    func upsertShares(userId: String,
                      shares: [Share],
                      eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?) async throws

    func getUsersLinkedToVaultShare(to shareId: String, lastToken: String?) async throws
        -> PaginatedUsersLinkedToShare
    func getUsersLinkedToItemShare(to shareId: String, itemId: String, lastToken: String?) async throws
        -> PaginatedUsersLinkedToShare

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

    @discardableResult
    func createVault(userId: String?, vault: VaultContent) async throws -> Share

    func edit(oldVault: Share, newVault: VaultContent) async throws

    /// Delete vault. If vault is not empty (0 active & trashed items)  an error is thrown.
    func deleteVault(shareId: String) async throws

    @discardableResult
    func transferVaultOwnership(vaultShareId: String, newOwnerShareId: String) async throws -> Bool
}

public extension ShareRepositoryProtocol {
    func upsertShares(userId: String, shares: [Share]) async throws {
        try await upsertShares(userId: userId, shares: shares, eventStream: nil)
    }
}

public actor ShareRepository: ShareRepositoryProtocol {
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let userManager: any UserManagerProtocol
    private let localDatasource: any LocalShareDatasourceProtocol
    private let remoteDatasource: any RemoteShareDatasourceProtocol
    private let passKeyManager: any PassKeyManagerProtocol
    private let logger: Logger

    public init(symmetricKeyProvider: any SymmetricKeyProvider,
                userManager: any UserManagerProtocol,
                localDatasource: any LocalShareDatasourceProtocol,
                remoteDatasource: any RemoteShareDatasourceProtocol,
                passKeyManager: any PassKeyManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.symmetricKeyProvider = symmetricKeyProvider
        self.localDatasource = localDatasource
        self.remoteDatasource = remoteDatasource
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

    func getShare(shareId: String) async throws -> Share? {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Getting local share with \(shareId) for user \(userId)")
        guard let share = try await localDatasource.getShare(userId: userId, shareId: shareId) else {
            return nil
        }
        logger.trace("Got local share with shareID \(shareId) for user \(userId)")
        return share.share
    }

    func getDecryptedShares(userId: String) async throws -> [Share] {
        logger.trace("Getting local shares for user \(userId)")

        let shares = try await getShares(userId: userId)
        let symmetricKey = try await getSymmetricKey()
        let decriptedShares = try shares.map { share -> Share in
            try share.withVaultContentDecrypted(symmetricKey: symmetricKey)
        }
        logger.trace("Got \(decriptedShares.count) local shares for user \(userId)")
        return decriptedShares
    }

    func getDecryptedShare(shareId: String) async throws -> Share? {
        let userId = try await userManager.getActiveUserId()
        let symmetricKey = try await getSymmetricKey()
        logger.trace("Getting local share with shareID \(shareId) for user \(userId)")
        guard let share = try await localDatasource.getShare(userId: userId, shareId: shareId) else {
            logger.trace("Found no local share with shareID \(shareId) for user \(userId)")
            return nil
        }
        logger.trace("Got local share with shareID \(shareId) for user \(userId)")
        return try share.withVaultContentDecrypted(symmetricKey: symmetricKey)
    }

    /// Get all remote shares for a user. This function decrypts the content of vault and fills up the
    /// `vaultContent` of share if possible
    func getDecryptedRemoteShares(userId: String) async throws -> [Share] {
        logger.trace("Getting all remote shares for user \(userId)")
        do {
            let shares = try await remoteDatasource.getShares(userId: userId)
            let decryptedShares: [Share] = try await shares
                .compactParallelMap(parallelism: 5) { [weak self] in
                    guard let self else { return nil }
                    do {
                        return try await decryptVaultContent(userId: userId, $0)
                    } catch {
                        if error.isInactiveUserKey {
                            logger.warning(error.localizedDebugDescription)
                            return nil
                        } else {
                            throw error
                        }
                    }
                }
            logger.trace("Got \(shares.count) remote shares for user \(userId)")
            return decryptedShares
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
                      eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?) async throws {
        let shareIds = shares.map(\.id)
        logger.trace("Upserting \(shares.count) shares for user \(userId), shares \(shareIds)")
        let key = try await getSymmetricKey()
        let encryptedShares = try await shares
            .parallelMap { [weak self] in
                eventStream?.send(.decryptedVault($0))
                // swiftlint:disable:next discouraged_optional_self
                return try await self?.symmetricallyEncryptNullable(userId: userId, $0, symmetricKey: key)
            }
            .compactMap { $0 }
        try await localDatasource.upsertShares(encryptedShares, userId: userId)

        logger.trace("Upserted \(shares.count) shares for user \(userId), shares \(shareIds)")
    }

    func getUsersLinkedToVaultShare(to shareId: String,
                                    lastToken: String?) async throws -> PaginatedUsersLinkedToShare {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Getting all users linked to shareId \(shareId)")
        let paginatedUsers = try await remoteDatasource.getUsersLinkedToVaultShare(userId: userId,
                                                                                   shareId: shareId,
                                                                                   lastToken: lastToken)
        logger.trace("Got \(paginatedUsers.shares.count) remote user for \(shareId)")
        return paginatedUsers
    }

    func getUsersLinkedToItemShare(to shareId: String,
                                   itemId: String,
                                   lastToken: String?) async throws -> PaginatedUsersLinkedToShare {
        let userId = try await userManager.getActiveUserId()
        logger.trace("Getting all users linked to shareId \(shareId), itemId \(itemId)")
        let paginatedUsers = try await remoteDatasource.getUsersLinkedToItemShare(userId: userId,
                                                                                  shareId: shareId,
                                                                                  itemId: itemId,
                                                                                  lastToken: lastToken)
        logger.trace("Got \(paginatedUsers.shares.count) remote user for \(shareId), itemId \(itemId)")
        return paginatedUsers
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
            let updated = try await remoteDatasource.updateUserSharePermission(userId: userId,
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
            let deleted = try await remoteDatasource.deleteUserShare(userId: userId,
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
        let deleted = try await remoteDatasource.deleteShare(userId: userId, shareId: shareId)
        logger.trace("Deleted \(deleted) user share \(logInfo)")
        return deleted
    }
}

// MARK: - Vaults

public extension ShareRepository {
    func createVault(userId: String?, vault: VaultContent) async throws -> Share {
        let userData: UserData = if let userId,
                                    let userData = try await userManager.getUserData(userId) {
            userData
        } else {
            try await userManager.getUnwrappedActiveUserData()
        }

        let userId = userData.user.ID
        logger.trace("Creating vault for user \(userId)")
        let request = try CreateVaultRequest(userData: userData, vault: vault)
        let createdVault = try await remoteDatasource.createVault(userId: userId, request: request)
        let key = try await getSymmetricKey()
        let encryptedShare = try await symmetricallyEncrypt(userId: userId, createdVault, symmetricKey: key)
        logger.trace("Saving newly created vault to local for user \(userId)")
        try await localDatasource.upsertShares([encryptedShare], userId: userId)
        logger.trace("Created vault for user \(userId)")
        return createdVault
    }

    func edit(oldVault: Share, newVault: VaultContent) async throws {
        let userData = try await userManager.getUnwrappedActiveUserData()
        let userId = userData.user.ID
        logger.trace("Editing vault \(oldVault.id) for user \(userId)")
        let shareId = oldVault.id
        let shareKey = try await passKeyManager.getLatestShareKey(userId: userId, shareId: shareId)
        let request = try UpdateVaultRequest(vault: newVault, shareKey: shareKey)
        let updatedVault = try await remoteDatasource.updateVault(userId: userId,
                                                                  request: request,
                                                                  shareId: shareId)
        logger.trace("Saving updated vault \(oldVault.id) to local for user \(userId)")
        let key = try await getSymmetricKey()
        let encryptedShare = try await symmetricallyEncrypt(userId: userId, updatedVault, symmetricKey: key)
        try await localDatasource.upsertShares([encryptedShare], userId: userId)
        logger.trace("Updated vault \(oldVault.id) for user \(userId)")
    }

    func deleteVault(shareId: String) async throws {
        let userId = try await userManager.getActiveUserId()
        // Remote deletion
        logger.trace("Deleting remote vault \(shareId) for user \(userId)")
        try await remoteDatasource.deleteVault(userId: userId, shareId: shareId)
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
        let updated = try await remoteDatasource.transferVaultOwnership(userId: userId,
                                                                        vaultShareId: vaultShareId,
                                                                        request: request)
        logger.info("Finished transfer of ownership")
        return updated
    }
}

private extension ShareRepository {
    func decryptVaultContent(userId: String, _ share: Share) async throws -> Share {
        guard share.isVaultRepresentation,
              let content = share.content,
              let keyRotation = share.contentKeyRotation else {
            return share
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
        var updatedShare = share
        updatedShare.vaultContent = try VaultContent(data: decryptedContent)

        return updatedShare
    }

    func getSymmetricKey() async throws -> SymmetricKey {
        try await symmetricKeyProvider.getSymmetricKey()
    }

    func symmetricallyEncrypt(userId: String,
                              _ share: Share,
                              symmetricKey: SymmetricKey) async throws -> SymmetricallyEncryptedShare {
        let decryptedContent: Data
        if let vaultContent = share.vaultContent {
            decryptedContent = try vaultContent.data()
        } else {
            guard let content = try await decryptVaultContent(userId: userId, share).vaultContent else {
                return .init(encryptedContent: nil, share: share)
            }
            decryptedContent = try content.data()
        }
        let reencryptedContent = try symmetricKey.encrypt(decryptedContent.encodeBase64())
        return .init(encryptedContent: reencryptedContent, share: share)
    }

    /// Symmetrically encrypt but return `nil` when encounting inactive user key instead of throwing
    /// We don't want to throw errors and stop the whole decryption process when we find an inactive user key
    @Sendable func symmetricallyEncryptNullable(userId: String,
                                                _ share: Share,
                                                symmetricKey: SymmetricKey) async throws
        -> SymmetricallyEncryptedShare? {
        do {
            return try await symmetricallyEncrypt(userId: userId, share, symmetricKey: symmetricKey)
        } catch {
            if error.isInactiveUserKey {
                logger.warning(error.localizedDebugDescription)
                return nil
            } else {
                throw error
            }
        }
    }
}

private extension SymmetricallyEncryptedShare {
    func withVaultContentDecrypted(symmetricKey: SymmetricKey) throws -> Share {
        guard share.shareType == .vault, let encryptedContent else { return share }

        let decryptedContent = try symmetricKey.decrypt(encryptedContent)
        guard let decryptedContentData = try decryptedContent.base64Decode() else { return share }
        let vaultContent = try VaultContent(data: decryptedContentData)

        return share.copy(with: vaultContent)
    }
}
