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
    func delete(userId: String, shareId: String, folderIds: [String]) async throws
    func deleteLocalFolder(userId: String, shareId: String, folderIds: [String]) async throws
    @discardableResult
    func createFolder(userId: String,
                      shareId: String,
                      parentFolderId: String?,
                      folderContent: FolderContent) async throws -> Folder
    func edit(userId: String, shareId: String, folderId: String, folderContent: FolderContent) async throws
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

    func deleteLocalFolder(userId: String, shareId: String, folderIds: [String]) async throws {
        // Local deletion
        logger.trace("Deleting local vault \(shareId) for user \(userId)")
        try await localDatasource.deleteFolders(folderIds: folderIds, shareId: shareId)
        logger.trace("Deleted local folders \(folderIds) for user \(userId)")
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
                        return try await symmetricallyEncrypt(userId: userId,
                                                              shareId: shareId,
                                                              folderRevision: folder)
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
        try await localDatasource.upsertFolders(encryptedFolders, userId: userId)
        logger.trace("Saved \(encryptedFolders.count) remote folders revisions to local database")
    }

    func deleteAllLocalFolders(userId: String) async throws {
        logger.trace("Deleting all local folder of user \(userId)")
        try await localDatasource.removeAllFolders(userId: userId)
        logger.trace("Deleted all local folder")
    }

    func delete(userId: String, shareId: String, folderIds: [String]) async throws {
        // Remote deletion
        logger.trace("Deleting remote folders \(folderIds) for user \(userId)")
        try await remoteDatasource.delete(userId: userId, shareId: shareId, folderId: folderIds)
        logger.trace("Deleted remote folders \(folderIds) for user \(userId)")
        // Local deletion
        logger.trace("Deleting local vault \(shareId) for user \(userId)")
        try await localDatasource.deleteFolders(folderIds: folderIds, shareId: shareId)
        logger.trace("Deleted local folders \(folderIds) for user \(userId)")

        logger.trace("Finished deleting folders \(folderIds) for user \(userId)")
    }

    func createFolder(userId: String,
                      shareId: String,
                      parentFolderId: String?,
                      folderContent: FolderContent) async throws -> Folder {
        logger.trace("Creating folder for user \(userId)")
        let containerKey = try await passKeyManager.getDecryptionKey(userId: userId,
                                                                     containerId: parentFolderId ?? shareId)
        let request = try CreateFolderRequest(encryptionKey: containerKey,
                                              folderContent: folderContent,
                                              parentFolderId: parentFolderId)
        let newFolder = try await remoteDatasource.create(userId: userId, shareId: shareId, request: request)
        try await passKeyManager.decryptAndStoreFolderKeys(shareId: shareId, folders: [newFolder])
        let encryptedFolder = try await symmetricallyEncrypt(userId: userId,
                                                             shareId: shareId,
                                                             folderRevision: newFolder)
        logger.trace("Saving newly created folder to local for user \(userId)")
        try await localDatasource.upsertFolders([encryptedFolder], userId: userId)
        logger.trace("Created folder for user \(userId)")
        return newFolder
    }

    func edit(userId: String, shareId: String, folderId: String, folderContent: FolderContent) async throws {
        logger.trace("Editing folder \(folderId) for user \(userId)")
        let folderKey = try await passKeyManager.getDecryptionKey(userId: userId, containerId: folderId)
        let requestPayload = try UpdateFolderRequestPayload(encryptionKey: folderKey, folderContent: folderContent)
        let request = UpdateFolderRequest(content: requestPayload)
        let updatedFolder = try await remoteDatasource.update(userId: userId,
                                                              shareId: shareId,
                                                              folderId: folderId,
                                                              request: request)
        logger.trace("Saving updated folder \(folderId) to local for user \(userId)")
        let encryptedFolder = try await symmetricallyEncrypt(userId: userId,
                                                             shareId: shareId,
                                                             folderRevision: updatedFolder)
        try await localDatasource.upsertFolders([encryptedFolder], userId: userId)
        logger.trace("Updated folder \(encryptedFolder.folderId) for user \(userId)")
    }
}

// public extension CreateFolderRequest {
//    init(encryptionKey: any CryptographicKeyProtocol, folderContent: FolderContent, parentFolderId: String?) throws {
//        let folderKey = try Data.random()
//        let encryptedContent = try AES.GCM.seal(folderContent.data(),
//                                                key: folderKey,
//                                                associatedData: .folderContent)
//        let encryptedFolderKey = try AES.GCM.seal(folderKey,
//                                                key: encryptionKey.keyData,
//                                                associatedData: .folderKey)
//        self.init(parentFolderID: parentFolderId,
//                  keyRotation: Int(encryptionKey.keyRotation),
//                  contentFormatVersion: Constants.ContentFormatVersion.folder,
//                  content: encryptedContent.base64EncodedString(),
//                  folderKey: encryptedFolderKey.base64EncodedString())
//    }
// }

// init(containerKey: any CryptographicKeyProtocol, itemContent: any ProtobufableItemContentProtocol) throws {
//    let itemKey = try Data.random()
//    let encryptedContent = try AES.GCM.seal(itemContent.data(),
//                                            key: itemKey,
//                                            associatedData: .itemContent)
//
//    let encryptedItemKey = try AES.GCM.seal(itemKey,
//                                            key: containerKey.keyData,
//                                            associatedData: .itemKey)
//
//    self.init(keyRotation: containerKey.keyRotation,
//              contentFormatVersion: Int16(Constants.ContentFormatVersion.item),
//              content: encryptedContent.base64EncodedString(),
//              itemKey: encryptedItemKey.base64EncodedString())
// }
// }

// func updateItem(userId: String,
//                oldItem: Item,
//                newItemContent: any ProtobufableItemContentProtocol,
//                shareId: String,
//                slNote: String?) async throws -> SymmetricallyEncryptedItem {
//    let itemId = oldItem.itemID
//    logger.trace("Updating item \(itemId) for share \(shareId)")
//
//    let latestItemKey: any CryptographicKeyProtocol = if oldItem.isASharedWithMeItem {
//        try await passKeyManager.getLatestShareKey(userId: userId, shareId: shareId)
//    } else {
//        try await passKeyManager.getDecryptionKey(userId: userId, containerId: oldItem.folderID ?? shareId,
//                                                  keyRotation: oldItem.keyRotation)
//    }
//
//    let request = try UpdateItemRequest(oldRevision: oldItem,
//                                        key: latestItemKey.keyData,
//                                        keyRotation: latestItemKey.keyRotation,
//                                        itemContent: newItemContent)
//
//    let updatedItemRevision =
//        try await remoteDatasource.updateItem(userId: userId,
//                                              shareId: shareId,
//                                              itemId: itemId,
//                                              request: request)
//    logger.trace("Finished updating remotely item \(itemId) for share \(shareId)")
//    let symmetricKey = try await getSymmetricKey()
//    let encryptedItem = try await symmetricallyEncrypt(itemRevision: updatedItemRevision,
//                                                       shareId: shareId,
//                                                       userId: userId,
//                                                       symmetricKey: symmetricKey,
//                                                       slNote: slNote)
//    try await localDatasource.upsertItems([encryptedItem])
//    itemsWereUpdated.send()
//    try await refreshPinnedItemDataStream()
//    logger.trace("Finished updating locally item \(itemId) for share \(shareId)")
//    return encryptedItem
// }

// extension CreateItemRequest {
//    init(containerKey: any CryptographicKeyProtocol, itemContent: any ProtobufableItemContentProtocol) throws {
//        let itemKey = try Data.random()
//        let encryptedContent = try AES.GCM.seal(itemContent.data(),
//                                                key: itemKey,
//                                                associatedData: .itemContent)
//
//        let encryptedItemKey = try AES.GCM.seal(itemKey,
//                                                key: containerKey.keyData,
//                                                associatedData: .itemKey)
//
//        self.init(keyRotation: containerKey.keyRotation,
//                  contentFormatVersion: Int16(Constants.ContentFormatVersion.item),
//                  content: encryptedContent.base64EncodedString(),
//                  itemKey: encryptedItemKey.base64EncodedString())
//    }
// }
//
// func createItemRequest(itemContent: any ProtobufableItemContentProtocol,
//                       userId: String,
//                       shareId: String) async throws -> CreateItemRequest {
//    // TODO: check if we need to get parent key to encrypt or style shared key
//    let latestKey = try await passKeyManager.getLatestShareKey(userId: userId, shareId: shareId)
//    return try CreateItemRequest(containerKey: latestKey, itemContent: itemContent)
// }

// func create(userId: String, shareId: String, request: CreateFolderRequest) async throws -> Folder
//
//
//
//
// func edit(oldVault: Share, newVault: VaultContent) async throws {
//    let userData = try await userManager.getUnwrappedActiveUserData()
//    let userId = userData.user.ID
//    logger.trace("Editing vault \(oldVault.id) for user \(userId)")
//    let shareId = oldVault.id
//    let shareKey = try await passKeyManager.getLatestShareKey(userId: userId, shareId: shareId)
//    let request = try UpdateVaultRequest(vault: newVault, shareKey: shareKey)
//    let updatedVault = try await remoteDatasource.updateVault(userId: userId,
//                                                              request: request,
//                                                              shareId: shareId)
//    logger.trace("Saving updated vault \(oldVault.id) to local for user \(userId)")
//    let key = try await getSymmetricKey()
//    let encryptedShare = try await symmetricallyEncrypt(userId: userId, updatedVault, symmetricKey: key)
//    try await localDatasource.upsertShares([encryptedShare], userId: userId)
//    logger.trace("Updated vault \(oldVault.id) for user \(userId)")
// }

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
    func symmetricallyEncrypt(userId: String,
                              shareId: String,
                              folderRevision: Folder) async throws -> SymmetricallyEncryptedFolder {
        let symmetricKey = try await symmetricKey

        print("woot getting containerKey")
        let containerKey: any CryptographicKeyProtocol = try await passKeyManager.getDecryptionKey(userId: userId,
                                                                                                   containerId: folderRevision
                                                                                                       .id)
        print("woot got containerKey: \(containerKey)")
        print("woot getting content of folder")

        let contentProtobuf = try folderRevision.getContent(containerKey: containerKey)
        print("woot got content of folder: \(contentProtobuf)")
        print("woot got encrypting content of folder")

        let encryptedContent = try contentProtobuf.encrypt(symmetricKey: symmetricKey)
        print("woot finished encrypting content of folder")

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
        print("woot getting keyRotation")
        guard containerKey.keyRotation == keyRotation else {
            throw PassError.crypto(.unmatchedKeyRotation(lhsKey: containerKey.keyRotation,
                                                         rhsKey: Int64(keyRotation)))
        }

        print("woot base decoding content")

        guard let contentData = try content.base64Decode() else {
            throw PassError.crypto(.failedToBase64Decode)
        }

        let decryptionKey = containerKey.keyData
        print("woot trying to open content")

        let decryptedContentData = try AES.GCM.open(contentData,
                                                    key: decryptionKey,
                                                    associatedData: .folderContent)

        print("woot finisehd decrypting content")

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
