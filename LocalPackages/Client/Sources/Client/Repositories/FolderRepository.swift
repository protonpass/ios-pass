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

public protocol FolderRepositoryProtocol: Sendable {
    // MARK: - Local functions

    func getAllLocalFolders(userId: String) async throws -> [SymmetricallyEncryptedFolder]
    func refreshFolders(userId: String, shareId: String) async throws
    func deleteAllLocalFolders(userId: String) async throws
}

public final class FolderRepository: FolderRepositoryProtocol {
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
}

// MARK: - Remote CRUD

public extension FolderRepository {
    func refreshFolders(userId: String,
                        shareId: String) async throws {
        logger.trace("Refreshing folders for share id: \(shareId)")

        var sinceToken: String?
        var folders = [Folder]()
        while true {
            let paginatedFolders = try await remoteDatasource.getFolders(userId: userId,
                                                                         shareId: shareId,
                                                                         sinceToken: sinceToken)
            if paginatedFolders.folders.isEmpty {
                break
            }
            folders.append(contentsOf: paginatedFolders.folders)
            sinceToken = paginatedFolders.lastToken
        }

        try await passKeyManager.decryptAndStoreFolderKeys(shareId: shareId, folders: folders)
        // Need to decrypt and store all keys of folder in PassKeymanager to have all the parents decryption keys
        // when decrypting folder content.

        let numberOfFolder = folders.count
        logger.trace("Got \(numberOfFolder) folders from remote for share \(shareId)")
        logger.trace("Encrypting \(numberOfFolder) remote folders for share \(shareId)")
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
                        return try await symmetricallyEncrypt(folderRevision: folder,
                                                              shareId: shareId,
                                                              userId: userId)
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

//        for folder in folders {
//            let encryptedFolder = try await symmetricallyEncrypt(folderRevision: folder,
//                                                               shareId: shareId,
//                                                               userId: userId)
        ////            eventStream?.send(.decryptItems(.init(shareId: shareId,
        ////                                                  total: itemRevisions.count,
        ////                                                  decrypted: index + 1)))
//            encryptedFolders.append(encryptedFolder)
//        }

        logger.trace("Removing all local old folders if any for share \(shareId)")
        try await localDatasource.removeAllFolders(shareId: shareId)
        logger.trace("Removed all local old folders for share \(shareId)")

        logger.trace("Saving \(encryptedFolders.count) remote folders revisions to local database")
        try await localDatasource.upsertFolders(encryptedFolders)
        logger.trace("Saved \(encryptedFolders.count) remote folders revisions to local database")
    }

    func deleteAllLocalFolders(userId: String) async throws {
        logger.trace("Deleting all local folder of user \(userId)")
        try await localDatasource.removeAllFolders(userId: userId)
        logger.trace("Deleted all local folder")
    }
}

// try await withThrowingTaskGroup(of: TempDirectoryTransferableUrl?.self,
//                                returning: [String: URL].self) { group in
//    for photo in photos {
//        group.addTask {
//            try await photo.loadTransferable(type: TempDirectoryTransferableUrl.self)
//        }
//    }
//
//    var contentUrls: [String: URL] = [:]
//
//    for try await url in group {
//        if let url {
//            contentUrls["Screenshot - \(url.value.lastPathComponent)"] = url.value
//        }
//    }
//
//    return contentUrls
// }
// MARK: - Private util functions

// private extension ItemRepository {
//    func getSymmetricKey() async throws -> SymmetricKey {
//        try await symmetricKeyProvider.getSymmetricKey()
//    }
// func getFolders(userId: String,
//                shareId: String,
//                sinceToken: String?,
//                pageSize: Int) async throws -> PaginatedFolders
//
//
// func refreshItems(userId: String,
//                  shareId: String,
//                  eventStream: PassthroughSubject<VaultSyncProgressEvent, Never>?) async throws {
//    logger.trace("Refreshing share \(shareId)")
//    let itemRevisions = try await remoteDatasource.getItems(userId: userId,
//                                                            shareId: shareId,
//                                                            eventStream: eventStream)
//    logger.trace("Got \(itemRevisions.count) items from remote for share \(shareId)")
//
//    logger.trace("Encrypting \(itemRevisions.count) remote items for share \(shareId)")
//    var encryptedItems = [SymmetricallyEncryptedItem]()
//
//    let symmetricKey = try await getSymmetricKey()
//    for (index, itemRevision) in itemRevisions.enumerated() {
//        let encryptedItem = try await symmetricallyEncrypt(itemRevision: itemRevision,
//                                                           shareId: shareId,
//                                                           userId: userId,
//                                                           symmetricKey: symmetricKey)
//        eventStream?.send(.decryptItems(.init(shareId: shareId,
//                                              total: itemRevisions.count,
//                                              decrypted: index + 1)))
//        encryptedItems.append(encryptedItem)
//    }
//
//    logger.trace("Removing all local old items if any for share \(shareId)")
//    try await localDatasource.removeAllItems(shareId: shareId)
//    logger.trace("Removed all local old items for share \(shareId)")
//
//    logger.trace("Saving \(itemRevisions.count) remote item revisions to local database")
//    try await localDatasource.upsertItems(encryptedItems)
//    logger.trace("Saved \(encryptedItems.count) remote item revisions to local database")
//
//    logger.trace("Refreshing last event ID for share \(shareId)")
//    try await shareEventIDRepository.getLastEventId(forceRefresh: true,
//                                                    userId: userId,
//                                                    shareId: shareId)
//    try await refreshPinnedItemDataStream()
//    logger.trace("Refreshed last event ID for share \(shareId)")
// }

private extension FolderRepository {
    func symmetricallyEncrypt(folderRevision: Folder,
                              shareId: String,
                              userId: String) async throws -> SymmetricallyEncryptedFolder {
        let symmetricKey = try await symmetricKey

        let containerId = folderRevision.parentFolderID ?? shareId
        let containerKey: any CryptographicKeyProtocol = try await passKeyManager.getDecryptionKey(userId: userId,
                                                                                                   containerId: containerId,
                                                                                                   keyRotation: folderRevision
                                                                                                       .keyRotation)
        let contentProtobuf = try folderRevision.getContent(containerKey: containerKey)
        let encryptedContent = try contentProtobuf.encrypt(symmetricKey: symmetricKey)

        return SymmetricallyEncryptedFolder(shareId: shareId,
                                            userId: userId,
                                            folder: folderRevision,
                                            encryptedContent: encryptedContent)
    }

//    // The key can be from folder or share
//    func decryptFolderContent(_ folderRevision: Folder, containerKey: any CryptographicKeyProtocol) throws ->
//    FolderContent {
//        guard containerKey.keyRotation == folderRevision.keyRotation else {
//            throw PassError.crypto(.unmatchedKeyRotation(lhsKey: containerKey.keyRotation,
//                                                         rhsKey: Int64(folderRevision.keyRotation)))
//        }
//
//        guard let contentData = try folderRevision.content.base64Decode() else {
//            throw PassError.crypto(.failedToBase64Decode)
//        }
//
    ////        let decryptionKey: Data
    ////        if let itemKey {
    ////            guard let itemKeyData = try itemKey.base64Decode() else {
    ////                throw PassError.crypto(.failedToBase64Decode)
    ////            }
    ////            decryptionKey = try AES.GCM.open(itemKeyData,
    ////                                             key: containerKey.keyData,
    ////                                             associatedData: .itemKey)
    ////        } else {
    ////            decryptionKey = containerKey.keyData
    ////        }
//
//        let decryptionKey = containerKey.keyData
//
//        let decryptedContentData = try AES.GCM.open(contentData,
//                                                    key: decryptionKey,
//                                                    associatedData: .folderContent)
//
//        return try FolderContent(data: decryptedContentData)
//    }

//
//    func createItemRequest(itemContent: any ProtobufableItemContentProtocol,
//                           userId: String,
//                           shareId: String) async throws -> CreateItemRequest {
//        let latestKey = try await passKeyManager.getLatestShareKey(userId: userId, shareId: shareId)
//        return try CreateItemRequest(containerKey: latestKey, itemContent: itemContent)
//    }
}

//
//// The key can be from folder or share
// func getContentProtobuf(containerKey: any CryptographicKeyProtocol) throws -> ItemContentProtobuf {
//    guard containerKey.keyRotation == keyRotation else {
//        throw PassError.crypto(.unmatchedKeyRotation(lhsKey: containerKey.keyRotation,
//                                                     rhsKey: keyRotation))
//    }
//
//    guard let contentData = try content.base64Decode() else {
//        throw PassError.crypto(.failedToBase64Decode)
//    }
//
//    let decryptionKey: Data
//    if let itemKey {
//        guard let itemKeyData = try itemKey.base64Decode() else {
//            throw PassError.crypto(.failedToBase64Decode)
//        }
//        decryptionKey = try AES.GCM.open(itemKeyData,
//                                         key: containerKey.keyData,
//                                         associatedData: .itemKey)
//    } else {
//        decryptionKey = containerKey.keyData
//    }
//
//    let decryptedContentData = try AES.GCM.open(contentData,
//                                                key: decryptionKey,
//                                                associatedData: .itemContent)
//
//    return try ItemContentProtobuf(data: decryptedContentData)
// }

extension Folder {
    // The key can be from folder or share
    func getContent(containerKey: any CryptographicKeyProtocol) throws -> FolderContent {
        guard containerKey.keyRotation == keyRotation else {
            throw PassError.crypto(.unmatchedKeyRotation(lhsKey: containerKey.keyRotation,
                                                         rhsKey: Int64(keyRotation)))
        }

        guard let contentData = try content.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

//        let decryptionKey: Data
//        if let itemKey {
//            guard let itemKeyData = try itemKey.base64Decode() else {
//                throw PassError.crypto(.failedToBase64Decode)
//            }
//            decryptionKey = try AES.GCM.open(itemKeyData,
//                                             key: containerKey.keyData,
//                                             associatedData: .itemKey)
//        } else {
        let decryptionKey = containerKey.keyData
//        }

        let decryptedContentData = try AES.GCM.open(contentData,
                                                    key: decryptionKey,
                                                    associatedData: .folderContent)

        return try FolderContent(data: decryptedContentData)
    }
}

//
// func symmetricallyEncrypt(itemRevision: Item,
//                          shareId: String,
//                          userId: String,
//                          symmetricKey: SymmetricKey,
//                          slNote: String? = nil) async throws -> SymmetricallyEncryptedItem {
//    let shareKey = try await passKeyManager.getShareKey(userId: userId,
//                                                        shareId: shareId,
//                                                        keyRotation: itemRevision.keyRotation)
//
//    let contentProtobuf = try itemRevision.getContentProtobuf(containerKey: shareKey)
//
//    let encryptedContent = try contentProtobuf.encrypt(symmetricKey: symmetricKey)
//
//    let isLogInItem = if case .login = contentProtobuf.contentData {
//        true
//    } else {
//        false
//    }
//
//    let encryptedSlNote: String? = if let slNote {
//        try symmetricKey.encrypt(slNote)
//    } else {
//        nil
//    }
//
//    return .init(shareId: shareId,
//                 userId: userId,
//                 folderId: itemRevision.folderID,
//                 item: itemRevision,
//                 encryptedContent: encryptedContent,
//                 isLogInItem: isLogInItem,
//                 encryptedSimpleLoginNote: encryptedSlNote)
// }
