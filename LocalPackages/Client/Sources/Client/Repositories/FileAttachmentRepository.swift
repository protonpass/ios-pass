//
// FileAttachmentRepository.swift
// Proton Pass - Created on 10/12/2024.
// Copyright (c) 2024 Proton Technologies AG
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

import Combine
import Core
import CryptoKit
import Entities
import Foundation
@preconcurrency import ProtonCoreDoh

// Redundant with `CodeOnlyReponse` on purpose because `CodeOnlyReponse` is used by
// core's network layer which has custom decode logic.
private struct UploadMultipartResponse: Decodable {
    let code: Int

    enum CodingKeys: String, CodingKey {
        case code = "Code"
    }
}

public protocol FileAttachmentRepositoryProtocol: Sendable {
    func createPendingFile(userId: String,
                           file: PendingFileAttachment) async throws -> RemotePendingFile
    /// Returns an async stream reporting upload progress (0.0 -> 1.0)
    func uploadFile(userId: String,
                    file: PendingFileAttachment) async throws -> AsyncThrowingStream<Float, any Error>
    func updatePendingFileName(userId: String,
                               file: PendingFileAttachment,
                               newName: String) async throws -> Bool
    func updateItemFileName(userId: String,
                            item: any ItemIdentifiable,
                            file: ItemFile,
                            newName: String) async throws -> ItemFile
    func linkFilesToItem(userId: String,
                         pendingFilesToAdd: [PendingFileAttachment],
                         existingFileIdsToRemove: [String],
                         item: any ItemIdentifiable) async throws
    func getActiveItemFiles(userId: String, item: any ItemIdentifiable, share: Share) async throws -> [ItemFile]
    func getItemFilesForAllRevisions(userId: String,
                                     item: any ItemIdentifiable,
                                     share: Share) async throws -> [ItemFile]
    func restoreFiles(userId: String,
                      item: any ItemIdentifiable,
                      files: [ItemFile]) async throws
}

public actor FileAttachmentRepository: FileAttachmentRepositoryProtocol {
    private let shareRepository: any ShareRepositoryProtocol
    private let itemRepository: any ItemRepositoryProtocol
    private let remoteFileDatasource: any RemoteFileDatasourceProtocol
    private let apiServiceLite: any ApiServiceLiteProtocol
    private let keyManager: any PassKeyManagerProtocol

    public init(shareRepository: any ShareRepositoryProtocol,
                itemRepository: any ItemRepositoryProtocol,
                remoteFileDatasource: any RemoteFileDatasourceProtocol,
                apiServiceLite: any ApiServiceLiteProtocol,
                keyManager: any PassKeyManagerProtocol) {
        self.shareRepository = shareRepository
        self.itemRepository = itemRepository
        self.remoteFileDatasource = remoteFileDatasource
        self.apiServiceLite = apiServiceLite
        self.keyManager = keyManager
    }
}

public extension FileAttachmentRepository {
    func createPendingFile(userId: String,
                           file: PendingFileAttachment) async throws -> RemotePendingFile {
        let metadata = try generateEncryptedMetadata(name: file.metadata.name,
                                                     mimeType: file.metadata.mimeType,
                                                     key: file.key)
        return try await remoteFileDatasource.createPendingFile(userId: userId,
                                                                metadata: metadata)
    }

    func uploadFile(userId: String,
                    file: PendingFileAttachment) async throws -> AsyncThrowingStream<Float, any Error> {
        guard let remoteId = file.remoteId else {
            throw PassError.fileAttachment(.failedToUploadMissingRemoteId)
        }

        let path = "/pass/v1/file/\(remoteId)/chunk"
        let tracker = FileProgressTracker(size: Int(file.metadata.size))

        return .asyncContinuation { [weak self] continuation in
            guard let self else {
                continuation.finish(throwing: PassError.deallocatedSelf)
                return
            }

            let process: (FileUtils.FileBlockData) async throws -> Void = { [weak self] blockData in
                guard let self else {
                    continuation.finish(throwing: PassError.deallocatedSelf)
                    return
                }
                let encryptedData = try AES.GCM.seal(blockData.value,
                                                     key: file.key,
                                                     associatedData: .fileData)
                let infos: [MultipartInfo] = [
                    .init(name: "ChunkIndex", data: blockData.index.toAsciiData),
                    .init(name: "ChunkData",
                          fileName: "no-op", // Not used by the BE but required
                          contentType: "application/octet-stream",
                          data: encryptedData)
                ]

                let eventStream: AsyncThrowingStream<ProgressEvent<UploadMultipartResponse>, any Error> =
                    try await apiServiceLite.uploadMultipart(path: path,
                                                             userId: userId,
                                                             infos: infos)

                for try await case let .progress(progress) in eventStream {
                    let overallProgress =
                        await tracker.overallProgress(currentProgress: progress,
                                                      chunkSize: blockData.value.count)
                    continuation.yield(overallProgress)
                }
            }

            let blockSize = Constants.Attachment.maxChunkSizeInBytes
            try await FileUtils.processBlockByBlock(file.metadata.url,
                                                    blockSizeInBytes: blockSize,
                                                    process: process)
            continuation.finish()
        }
    }

    func updatePendingFileName(userId: String,
                               file: PendingFileAttachment,
                               newName: String) async throws -> Bool {
        guard let remoteId = file.remoteId else {
            throw PassError.fileAttachment(.failedToUploadMissingRemoteId)
        }
        let metadata = try generateEncryptedMetadata(name: newName,
                                                     mimeType: file.metadata.mimeType,
                                                     key: file.key)
        return try await remoteFileDatasource.updatePendingFileMetadata(userId: userId,
                                                                        fileId: remoteId,
                                                                        metadata: metadata)
    }

    func updateItemFileName(userId: String,
                            item: any ItemIdentifiable,
                            file: ItemFile,
                            newName: String) async throws -> ItemFile {
        guard let mimeType = file.mimeType else {
            throw PassError.fileAttachment(.failedToUpdateMissingMimeType)
        }

        let itemKeys = try await keyManager.getItemKeys(userId: userId,
                                                        shareId: item.shareId,
                                                        itemId: item.itemId)

        guard let itemKey = itemKeys.first(where: { $0.keyRotation == file.itemKeyRotation }) else {
            throw PassError.fileAttachment(.missingItemKey(file.itemKeyRotation))
        }

        guard let encryptedFileKey = try file.fileKey.base64Decode() else {
            throw PassError.fileAttachment(.failedToDownloadMissingDecryptedFileKey(file.fileID))
        }

        let fileKey = try AES.GCM.open(encryptedFileKey,
                                       key: itemKey.keyData,
                                       associatedData: .fileKey)

        let metadata = try generateEncryptedMetadata(name: newName,
                                                     mimeType: mimeType,
                                                     key: fileKey)
        var updatedFile = try await remoteFileDatasource.updateFileMetadata(userId: userId,
                                                                            item: item,
                                                                            fileId: file.fileID,
                                                                            metadata: metadata)
        updatedFile.name = newName
        updatedFile.mimeType = file.mimeType
        return updatedFile
    }

    func linkFilesToItem(userId: String,
                         pendingFilesToAdd: [PendingFileAttachment],
                         existingFileIdsToRemove: [String],
                         item: any ItemIdentifiable) async throws {
        let itemKey = try await keyManager.getLatestItemKey(userId: userId,
                                                            shareId: item.shareId,
                                                            itemId: item.itemId)
        var filesToAdd = [FileToAdd]()
        for file in pendingFilesToAdd {
            guard let remoteId = file.remoteId else {
                throw PassError.fileAttachment(.failedToAttachMissingRemoteId)
            }
            let encryptedFileKey = try AES.GCM.seal(file.key,
                                                    key: itemKey.keyData,
                                                    associatedData: .fileKey)
            filesToAdd.append(.init(fileId: remoteId,
                                    fileKey: encryptedFileKey.base64EncodedString()))
        }

        var existingFileIdsToRemove = existingFileIdsToRemove

        guard let item = try await itemRepository.getItem(shareId: item.shareId,
                                                          itemId: item.itemId) else {
            throw PassError.itemNotFound(item)
        }
        let threshold = 10
        var updatedItem: Item
        while true {
            let toAdd = filesToAdd.popAndRemoveFirstElements(threshold)
            let toRemove = existingFileIdsToRemove.popAndRemoveFirstElements(threshold)

            if toAdd.isEmpty, toRemove.isEmpty {
                return
            }
            updatedItem = try await remoteFileDatasource.linkFilesToItem(userId: userId,
                                                                         item: item,
                                                                         filesToAdd: toAdd,
                                                                         fileIdsToRemove: toRemove)
        }
        try await itemRepository.upsertItems(userId: userId,
                                             items: [updatedItem],
                                             shareId: item.shareId)
    }

    func getActiveItemFiles(userId: String, item: any ItemIdentifiable, share: Share) async throws -> [ItemFile] {
        try await getAllFiles(userId: userId, share: share, item: item) { [weak self] lastId in
            guard let self else {
                throw PassError.deallocatedSelf
            }
            return try await remoteFileDatasource.getActiveFiles(userId: userId,
                                                                 item: item,
                                                                 lastId: lastId)
        }
    }

    func getItemFilesForAllRevisions(userId: String,
                                     item: any ItemIdentifiable,
                                     share: Share) async throws -> [ItemFile] {
        try await getAllFiles(userId: userId, share: share, item: item) { [weak self] lastId in
            guard let self else {
                throw PassError.deallocatedSelf
            }
            return try await remoteFileDatasource.getFilesForAllRevisions(userId: userId,
                                                                          item: item,
                                                                          lastId: lastId)
        }
    }

    func restoreFiles(userId: String,
                      item: any ItemIdentifiable,
                      files: [ItemFile]) async throws {
        guard let share = try await shareRepository.getShare(shareId: item.shareId) else {
            throw PassError.shareNotFoundInLocalDB(shareID: item.shareId)
        }
        let keys = try await keyManager.getShareKeys(userId: userId,
                                                     share: share,
                                                     item: item)
        guard let latestKey = keys.max(by: { $0.keyRotation > $1.keyRotation }) else {
            throw PassError.keysNotFound(shareID: item.shareId)
        }

        for file in files {
            guard let usedKey = keys.first(where: { $0.keyRotation == file.itemKeyRotation }) else {
                throw PassError.fileAttachment(.missingItemKey(file.itemKeyRotation))
            }

            guard let encryptedFileKey = try file.fileKey.base64Decode() else {
                throw PassError.crypto(.failedToBase64Decode)
            }

            // Open the file key
            let decryptedFileKey = try AES.GCM.open(encryptedFileKey,
                                                    key: usedKey.keyData,
                                                    associatedData: .fileKey)

            // Re-encrypt the file key with the latest share key
            let reencryptedFileKey = try AES.GCM.seal(decryptedFileKey,
                                                      key: latestKey.keyData,
                                                      associatedData: .fileKey)

            let encodedFileKey = reencryptedFileKey.base64EncodedString()
            let updatedItem =
                try await remoteFileDatasource.restoreFile(userId: userId,
                                                           item: item,
                                                           fileId: file.fileID,
                                                           fileKey: encodedFileKey,
                                                           itemKeyRevision: Int(latestKey.keyRotation))
            try await itemRepository.upsertItems(userId: userId,
                                                 items: [updatedItem],
                                                 shareId: item.shareId)
        }
    }
}

private extension FileAttachmentRepository {
    func getAllFiles(userId: String,
                     share: Share,
                     item: any ItemIdentifiable,
                     getFiles: (_ lastId: String?) async throws -> PaginatedItemFiles) async throws
        -> [ItemFile] {
        var lastId: String?
        var files = [ItemFile]()

        let keys = try await keyManager.getShareKeys(userId: userId,
                                                     share: share,
                                                     item: item)
        while true {
            let response = try await getFiles(lastId)
            for var file in response.files {
                guard let itemKey = keys.first(where: { $0.keyRotation == file.itemKeyRotation }) else {
                    throw PassError.crypto(.missingItemKeyRotation(file.itemKeyRotation))
                }

                guard let encryptedFileKey = try file.fileKey.base64Decode(),
                      let encryptedMetadata = try file.metadata.base64Decode() else {
                    throw PassError.crypto(.failedToBase64Decode)
                }

                let decryptedFileKey = try AES.GCM.open(encryptedFileKey,
                                                        key: itemKey.keyData,
                                                        associatedData: .fileKey)

                let decryptedMetadata = try AES.GCM.open(encryptedMetadata,
                                                         key: decryptedFileKey,
                                                         associatedData: .fileData)
                let metadata = try FileMetadata(serializedBytes: decryptedMetadata)
                file.name = metadata.name
                file.mimeType = metadata.mimeType
                files.append(file)
            }
            lastId = response.lastID
            if lastId == nil || files.count >= response.total {
                return files
            }
        }
    }

    func generateEncryptedMetadata(name: String,
                                   mimeType: String,
                                   key: Data) throws -> String {
        var protobuf = FileMetadata()
        protobuf.name = name
        protobuf.mimeType = mimeType
        let serializedProtobuf = try protobuf.serializedData()
        let encryptedProtobuf = try AES.GCM.seal(serializedProtobuf,
                                                 key: key,
                                                 associatedData: .fileData)
        return encryptedProtobuf.base64EncodedString()
    }
}
