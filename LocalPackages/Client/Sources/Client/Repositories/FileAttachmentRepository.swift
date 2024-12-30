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

    var isSuccessful: Bool {
        code == 1_000
    }

    enum CodingKeys: String, CodingKey {
        case code = "Code"
    }
}

public protocol FileAttachmentRepositoryProtocol: Sendable {
    func createPendingFile(userId: String,
                           file: PendingFileAttachment) async throws -> RemotePendingFile
    func uploadFile(userId: String,
                    file: PendingFileAttachment,
                    progress: @MainActor @escaping (Float) -> Void) async throws
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
    func getActiveItemFiles(userId: String, item: any ItemIdentifiable) async throws -> [ItemFile]
    func getItemFilesForAllRevisions(userId: String,
                                     item: any ItemIdentifiable) async throws -> [ItemFile]
}

public actor FileAttachmentRepository: FileAttachmentRepositoryProtocol {
    private let localItemDatasource: any LocalItemDatasourceProtocol
    private let remoteFileDatasource: any RemoteFileDatasourceProtocol
    private let apiServiceLite: any ApiServiceLiteProtocol
    private let keyManager: any PassKeyManagerProtocol

    private var cancellables = Set<AnyCancellable>()

    public init(localItemDatasource: any LocalItemDatasourceProtocol,
                remoteFileDatasource: any RemoteFileDatasourceProtocol,
                apiServiceLite: any ApiServiceLiteProtocol,
                keyManager: any PassKeyManagerProtocol) {
        self.localItemDatasource = localItemDatasource
        self.remoteFileDatasource = remoteFileDatasource
        self.apiServiceLite = apiServiceLite
        self.keyManager = keyManager
    }
}

@MainActor
public final class UploadProgressTracker {
    private var totalBytesSent: Int = 0

    public nonisolated init() {}

    public func updateProgress(bytesSent: Int, fileSize: Int, progress: @escaping (Float) -> Void) {
        totalBytesSent += bytesSent
        let progressValue = Float(totalBytesSent) / Float(fileSize)
        progress(progressValue)
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
                    file: PendingFileAttachment,
                    progress: @MainActor @escaping (Float) -> Void) async throws {
        guard let remoteId = file.remoteId else {
            throw PassError.fileAttachment(.failedToUploadMissingRemoteId)
        }

        let progressTracker = UploadProgressTracker()

        // Make sure file size is not 0 to avoid crash (can not divide by 0)
        let fileSize = max(1, Int(file.metadata.size))
        let path = "/pass/v1/file/\(remoteId)/chunk"

        let process: (FileUtils.FileBlockData) async throws -> Void = { [weak self] blockData in
            guard let self else {
                throw PassError.fileAttachment(.failedToEncryptFile)
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

            let response: UploadMultipartResponse =
                try await apiServiceLite.uploadMultipart(path: path,
                                                         userId: userId,
                                                         infos: infos) { bytesSent in
                    progressTracker.updateProgress(bytesSent: bytesSent, fileSize: fileSize, progress: progress)
                }

            if !response.isSuccessful {
                throw PassError.fileAttachment(.failedToUpload(response.code))
            }
        }

        try await FileUtils.processBlockByBlock(file.metadata.url,
                                                blockSizeInBytes: Constants.Utils.maxChunkSizeInBytes,
                                                process: process)
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

        guard let item = try await localItemDatasource.getItem(shareId: item.shareId,
                                                               itemId: item.itemId) else {
            throw PassError.itemNotFound(item)
        }
        let threshold = 10
        while true {
            let toAdd = filesToAdd.popAndRemoveFirstElements(threshold)
            let toRemove = existingFileIdsToRemove.popAndRemoveFirstElements(threshold)

            if toAdd.isEmpty, toRemove.isEmpty {
                return
            }
            try await remoteFileDatasource.linkFilesToItem(userId: userId,
                                                           item: item,
                                                           filesToAdd: toAdd,
                                                           fileIdsToRemove: toRemove)
        }
    }

    func getActiveItemFiles(userId: String, item: any ItemIdentifiable) async throws -> [ItemFile] {
        try await getFilesOfAllPages(userId: userId, item: item) { [weak self] lastId in
            guard let self else {
                throw PassError.deallocatedSelf
            }
            return try await remoteFileDatasource.getActiveFiles(userId: userId,
                                                                 item: item,
                                                                 lastId: lastId)
        }
    }

    func getItemFilesForAllRevisions(userId: String,
                                     item: any ItemIdentifiable) async throws -> [ItemFile] {
        try await getFilesOfAllPages(userId: userId, item: item) { [weak self] lastId in
            guard let self else {
                throw PassError.deallocatedSelf
            }
            return try await remoteFileDatasource.getFilesForAllRevisions(userId: userId,
                                                                          item: item,
                                                                          lastId: lastId)
        }
    }
}

private extension FileAttachmentRepository {
    func getFilesOfAllPages(userId: String,
                            item: any ItemIdentifiable,
                            getFiles: (_ lastId: String?) async throws -> PaginatedItemFiles) async throws
        -> [ItemFile] {
        var lastId: String?
        var files = [ItemFile]()
        let itemKeys = try await keyManager.getItemKeys(userId: userId,
                                                        shareId: item.shareId,
                                                        itemId: item.itemId)
        while true {
            let response = try await getFiles(lastId)
            for var file in response.files {
                guard let itemKey = itemKeys.first(where: { $0.keyRotation == file.itemKeyRotation }) else {
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
