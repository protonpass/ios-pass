//
// FolderRepository.swift
// Proton Pass - Created on 02/12/2025.
// Copyright (c) 2025 Proton Technologies AG
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
import CryptoKit
import Entities
import Foundation

// sourcery: AutoMockable
public protocol FolderRepositoryProtocol: Sendable {
    // MARK: - Local functions

    func getAllLocalFolders(userId: String) async throws -> [SymmetricallyEncryptedFolder]
    func deleteAllLocalFolders(userId: String) async throws
    func deleteLocalFolders(userId: String, shareId: String, folderIds: [String]) async throws
    func deleteLocal(folders: [any FolderIdentifiable], userId: String) async throws
    func deleteAllFoldersLocally(shareId: String, userId: String) async throws

    // MARK: - CRUD

    func refreshFolders(userId: String, shareId: String) async throws
    func delete(userId: String, shareId: String, folderIds: [String]) async throws
    @discardableResult
    func createFolder(userId: String,
                      shareId: String,
                      parentFolderId: String?,
                      folderContent: FolderContent) async throws -> Folder
    func edit(userId: String, shareId: String, folderId: String, folderContent: FolderContent) async throws
    func move(userId: String, shareId: String, folderId: String, destinationId: String?) async throws
    func refreshFolders(userId: String, foldersIds: [any FolderIdentifiable]) async throws
}

public final class FolderRepository: FolderRepositoryProtocol, Sendable {
    private let remoteDatasource: any RemoteFolderDatasourceProtocol
    private let localDatasource: any LocalFolderDatasourceProtocol
    private let symmetricKeyProvider: any SymmetricKeyProvider
    private let shareEventIDRepository: any ShareEventIDRepositoryProtocol
    private let passKeyManager: any PassKeyManagerProtocol
    private let logger: Logger

    private var symmetricKey: SymmetricKey {
        get async throws {
            try await symmetricKeyProvider.getSymmetricKey()
        }
    }

    public init(remoteDatasource: any RemoteFolderDatasourceProtocol,
                localDatasource: any LocalFolderDatasourceProtocol,
                symmetricKeyProvider: any SymmetricKeyProvider,
                shareEventIDRepository: any ShareEventIDRepositoryProtocol,
                passKeyManager: any PassKeyManagerProtocol,
                logManager: any LogManagerProtocol) {
        self.remoteDatasource = remoteDatasource
        self.localDatasource = localDatasource
        self.symmetricKeyProvider = symmetricKeyProvider
        self.shareEventIDRepository = shareEventIDRepository
        self.passKeyManager = passKeyManager
        logger = .init(manager: logManager)
    }
}

// MARK: - Local CRUD

public extension FolderRepository {
    func getAllLocalFolders(userId: String) async throws -> [SymmetricallyEncryptedFolder] {
        try await localDatasource.getAllFolders(userId: userId)
    }

    func deleteLocalFolders(userId: String, shareId: String, folderIds: [String]) async throws {
        // Local deletion
        logger.trace("Deleting \(folderIds.count) local folders in share: \(shareId) for user \(userId)")
        try await localDatasource.deleteFolders(userId: userId, folderIds: folderIds, shareId: shareId)
        logger.trace("Deleted local folders \(folderIds) for user \(userId)")
    }

    func deleteAllLocalFolders(userId: String) async throws {
        logger.trace("Deleting all local folders of user \(userId)")
        try await localDatasource.removeAllFolders(userId: userId)
        logger.trace("Deleted all local folders of user \(userId)")
    }

    func deleteLocal(folders: [any FolderIdentifiable], userId: String) async throws {
        logger.trace("Deleting \(folders.count) local folders of user \(userId)")
        try await localDatasource.deleteFolders(userId: userId, folders: folders)
        logger.trace("Deleted \(folders.count) local folders of user \(userId)")
    }

    func deleteAllFoldersLocally(shareId: String, userId: String) async throws {
        logger.trace("Deleting all folders locally for share \(shareId) of user \(userId)")
        try await localDatasource.deleteFolders(shareId: shareId, userId: userId)
        logger.trace("Deleted all folders locally for share \(shareId)")
    }
}

// MARK: - CRUD

public extension FolderRepository {
    func refreshFolders(userId: String,
                        shareId: String) async throws {
        logger.trace("Refreshing folders for share id: \(shareId)")

        var sinceToken: String?
        var folders = [Folder]()
        while true {
            do {
                let paginatedFolders = try await remoteDatasource.getFolders(userId: userId,
                                                                             shareId: shareId,
                                                                             sinceToken: sinceToken)
                if paginatedFolders.folders.isEmpty {
                    break
                }
                folders.append(contentsOf: paginatedFolders.folders)
                if paginatedFolders.lastToken == nil {
                    break
                }
                sinceToken = paginatedFolders.lastToken
            } catch {
                logger.error(message: "Failed to fetch folders for share \(shareId): \(error)", error: error)
                throw error
            }
        }

        // Remote returned no folders: the share has no folders, clear any stale local data.
        guard !folders.isEmpty else {
            logger.trace("No remote folders for share \(shareId), clearing local folders")
            try await localDatasource.removeAllFolders(shareId: shareId)
            return
        }

        let symmetricallyEncryptedFolders = try await batchSymmetricEncrypt(userId: userId,
                                                                            shareId: shareId,
                                                                            folders: folders)

        try await localDatasource.removeAllFolders(shareId: shareId)
        logger.trace("Saving \(symmetricallyEncryptedFolders.count) remote folders to local database")
        try await localDatasource.upsertFolders(symmetricallyEncryptedFolders, userId: userId)
        logger.trace("Saved \(symmetricallyEncryptedFolders.count) remote folders to local database")
    }

    func refreshFolders(userId: String, foldersIds: [any FolderIdentifiable]) async throws {
        let foldersByShare = Dictionary(grouping: foldersIds, by: { $0.shareId })

        try await withThrowingTaskGroup(of: Void.self) { [weak self] taskGroup in
            guard let self else { throw PassError.deallocatedSelf }
            for (shareId, folderIds) in foldersByShare {
                taskGroup.addTask { [weak self] in
                    guard let self else {
                        throw PassError.deallocatedSelf
                    }
                    try await refreshFolders(userId: userId, shareId: shareId, foldersIds: folderIds)
                }
            }
            try await taskGroup.waitForAll()
        }
    }

    func delete(userId: String, shareId: String, folderIds: [String]) async throws {
        // Remote deletion
        logger.trace("Deleting remote folders \(folderIds) for user \(userId)")
        try await remoteDatasource.delete(userId: userId, shareId: shareId, folderIds: folderIds)
        logger.trace("Deleted remote folders \(folderIds) for user \(userId)")
        // Local deletion
        logger.trace("Deleting local folders \(folderIds) for user \(userId)")
        try await localDatasource.deleteFolders(userId: userId, folderIds: folderIds, shareId: shareId)
        logger.trace("Finished deleting folders \(folderIds) in share \(shareId) for user \(userId)")
    }

    func createFolder(userId: String,
                      shareId: String,
                      parentFolderId: String?,
                      folderContent: FolderContent) async throws -> Folder {
        logger.trace("Creating folder for user \(userId)")
        let containerKey = try await passKeyManager.getContainerKey(containerId: parentFolderId ?? shareId,
                                                                    keyRotation: nil)
        let request = try CreateFolderRequest(encryptionKey: containerKey,
                                              folderContent: folderContent,
                                              parentFolderId: parentFolderId)
        let newFolder = try await remoteDatasource.create(userId: userId, shareId: shareId, request: request)
        try await passKeyManager.decryptAndStoreFolderKeys(shareId: shareId, folders: [newFolder])
        let encryptedFolder = try await symmetricallyEncrypt(userId: userId,
                                                             shareId: shareId,
                                                             folder: newFolder)
        logger.trace("Saving newly created folder to local for user \(userId)")
        try await localDatasource.upsertFolders([encryptedFolder], userId: userId)
        logger.trace("Created folder for user \(userId)")
        return newFolder
    }

    func edit(userId: String, shareId: String, folderId: String, folderContent: FolderContent) async throws {
        logger.trace("Editing folder \(folderId) for user \(userId)")
        let folderKey = try await passKeyManager.getContainerKey(containerId: folderId,
                                                                 keyRotation: nil)
        let requestPayload = try UpdateFolderRequestPayload(encryptionKey: folderKey, folderContent: folderContent)
        let request = UpdateFolderRequest(content: requestPayload)
        let updatedFolder = try await remoteDatasource.update(userId: userId,
                                                              shareId: shareId,
                                                              folderId: folderId,
                                                              request: request)
        logger.trace("Saving updated folder \(folderId) to local for user \(userId)")
        let encryptedFolder = try await symmetricallyEncrypt(userId: userId,
                                                             shareId: shareId,
                                                             folder: updatedFolder)
        try await localDatasource.upsertFolders([encryptedFolder], userId: userId)
        logger.trace("Updated folder \(encryptedFolder.folderId) for user \(userId)")
    }

    func move(userId: String, shareId: String, folderId: String, destinationId: String?) async throws {
        logger.trace("Move folder \(folderId) to destination \(destinationId ?? shareId)")
        let destinationKey = try await passKeyManager.getContainerKey(containerId: destinationId ?? shareId,
                                                                      keyRotation: nil)
        let currentFolderKey = try await passKeyManager.getContainerKey(containerId: folderId,
                                                                        keyRotation: nil)
        let encryptedItemKey = try AES.GCM.seal(currentFolderKey.keyData,
                                                key: destinationKey.keyData,
                                                associatedData: .folderKey)

        let request = MoveFolderRequest(parentFolderID: destinationId,
                                        folderKeys: [.init(folderKey: encryptedItemKey.base64EncodedString(),
                                                           keyRotation: Int(currentFolderKey.keyRotation))])
        let updatedFolder = try await remoteDatasource.move(userId: userId,
                                                            shareId: shareId,
                                                            folderId: folderId,
                                                            request: request)
        let encryptedFolder = try await symmetricallyEncrypt(userId: userId,
                                                             shareId: shareId,
                                                             folder: updatedFolder)
        logger.trace("Updating local datasource")
        try await localDatasource.deleteFolders(userId: userId, folderIds: [folderId], shareId: shareId)
        try await localDatasource.upsertFolders([encryptedFolder], userId: userId)
        logger.trace("Folder move completed successfully")
    }
}

private extension FolderRepository {
    func symmetricallyEncrypt(userId: String,
                              shareId: String,
                              folder: Folder) async throws -> SymmetricallyEncryptedFolder {
        let symmetricKey = try await symmetricKey

        let containerKey = try await passKeyManager.getContainerKey(containerId: folder.id,
                                                                    keyRotation: folder.keyRotation)

        let contentProtobuf = try folder.getContent(parentKey: containerKey)
        let encryptedContent = try contentProtobuf.encrypt(symmetricKey: symmetricKey)
        return SymmetricallyEncryptedFolder(shareId: shareId,
                                            userId: userId,
                                            folder: folder,
                                            encryptedContent: encryptedContent)
    }

    func refreshFolders(userId: String,
                        shareId: String,
                        foldersIds: [any FolderIdentifiable]) async throws {
        var folders = [Folder]()
        for batch in foldersIds.chunked(into: 20) {
            let batch = try await withThrowingTaskGroup(of: Folder.self,
                                                        returning: [Folder]
                                                            .self) { [weak self] taskGroup in
                guard let self else { throw PassError.deallocatedSelf }
                for folderIds in batch {
                    taskGroup.addTask { [weak self] in
                        guard let self else {
                            throw PassError.deallocatedSelf
                        }
                        return try await remoteDatasource.getFolder(userId: userId,
                                                                    shareId: folderIds.shareId,
                                                                    folderId: folderIds.folderId)
                    }
                }
                var encryptedFolders = [Folder]()

                for try await folder in taskGroup {
                    encryptedFolders.append(folder)
                }

                return encryptedFolders
            }
            folders.append(contentsOf: batch)
        }

        let symmetricallyEncryptedFolders = try await batchSymmetricEncrypt(userId: userId,
                                                                            shareId: shareId,
                                                                            folders: folders)

        guard !symmetricallyEncryptedFolders.isEmpty else {
            return
        }

        logger.trace("Saving \(symmetricallyEncryptedFolders.count) remote folders revisions to local database")
        try await localDatasource.upsertFolders(symmetricallyEncryptedFolders, userId: userId)
        logger.trace("Saved \(symmetricallyEncryptedFolders.count) remote folders revisions to local database")
    }

    func batchSymmetricEncrypt(userId: String,
                               shareId: String,
                               folders: [Folder]) async throws -> [SymmetricallyEncryptedFolder] {
        guard !folders.isEmpty else {
            return []
        }
        try await passKeyManager.decryptAndStoreFolderKeys(shareId: shareId, folders: folders)

        var encryptedFolders = [SymmetricallyEncryptedFolder]()

        for batch in folders.chunked(into: 20) {
            let batch = try await withThrowingTaskGroup(of: SymmetricallyEncryptedFolder.self,
                                                        returning: [SymmetricallyEncryptedFolder]
                                                            .self) { [weak self] taskGroup in
                guard let self else { throw PassError.deallocatedSelf }
                for folder in batch {
                    taskGroup.addTask { [weak self] in
                        guard let self else {
                            throw PassError.deallocatedSelf
                        }
                        return try await symmetricallyEncrypt(userId: userId,
                                                              shareId: shareId,
                                                              folder: folder)
                    }
                }
                var encryptedFolders = [SymmetricallyEncryptedFolder]()

                for try await symmetricallyEncryptedFolder in taskGroup {
                    encryptedFolders.append(symmetricallyEncryptedFolder)
                }

                return encryptedFolders
            }
            encryptedFolders.append(contentsOf: batch)
        }

        return encryptedFolders
    }
}
