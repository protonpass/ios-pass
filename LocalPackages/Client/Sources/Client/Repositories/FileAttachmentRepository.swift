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

import Core
import CryptoKit
import Entities
import Foundation
@preconcurrency import ProtonCoreDoh

// Redundant with `CodeOnlyReponse` on purpose because `CodeOnlyReponse` is used by
// core's network layer which has custom decode logic.
private struct UploadMultipartResponse: Decodable {
    let code: Int

    var isSuccesful: Bool {
        code == 1_000
    }

    enum CodingKeys: String, CodingKey {
        case code = "Code"
    }
}

public protocol FileAttachmentRepositoryProtocol: Sendable {
    func createPendingFile(userId: String,
                           file: PendingFileAttachment) async throws -> RemotePendingFile
    func uploadChunk(userId: String, file: PendingFileAttachment) async throws
    func linkFilesToItem(userId: String,
                         pendingFilesToAdd: [PendingFileAttachment],
                         existingFileIdsToRemove: [String],
                         item: any ItemIdentifiable) async throws
    func getActiveItemFiles(userId: String, item: any ItemIdentifiable) async throws -> [ItemFile]
}

public actor FileAttachmentRepository: FileAttachmentRepositoryProtocol {
    private let localItemDatasource: any LocalItemDatasourceProtocol
    private let remoteFileDatasource: any RemoteFileDatasourceProtocol
    private let apiServiceLite: any ApiServiceLiteProtocol
    private let keyManager: any PassKeyManagerProtocol

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

public extension FileAttachmentRepository {
    func createPendingFile(userId: String,
                           file: PendingFileAttachment) async throws -> RemotePendingFile {
        let protobuf = file.toProtobuf
        let serializedProtobuf = try protobuf.serializedData()
        let encryptedProtobuf = try AES.GCM.seal(serializedProtobuf,
                                                 key: file.key,
                                                 associatedData: .fileData)
        guard let metadata = encryptedProtobuf.combined?.base64EncodedString() else {
            throw PassError.fileAttachment(.failedToEncryptMetadata)
        }
        return try await remoteFileDatasource.createPendingFile(userId: userId,
                                                                metadata: metadata)
    }

    func uploadChunk(userId: String, file: PendingFileAttachment) async throws {
        guard let remoteId = file.remoteId else {
            throw PassError.fileAttachment(.failedToUploadMissingRemoteId)
        }

        guard let encryptedData = file.encryptedData else {
            throw PassError.fileAttachment(.failedToUploadMissingEncryptedData)
        }

        // 48 is the ASCII code of 0, we want to pass ChunkIndex as integer data
        // converting to UTF8 string doesn't work
        let zero = Data([48])
        let infos: [MultipartInfo] = [
            .init(name: "ChunkIndex", data: zero),
            .init(name: "ChunkData",
                  fileName: "no-op", // Not used by the BE but required
                  contentType: "application/octet-stream",
                  data: encryptedData)
        ]

        let response: UploadMultipartResponse =
            try await apiServiceLite.uploadMultipart(path: "/pass/v1/file/\(remoteId)/chunk",
                                                     userId: userId,
                                                     infos: infos)
        if !response.isSuccesful {
            throw PassError.fileAttachment(.failedToUpload(response.code))
        }
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
            guard let encryptedFileKeyData = encryptedFileKey.combined else {
                throw PassError.fileAttachment(.failedToAttachMissingEncryptedFileKey)
            }
            filesToAdd.append(.init(fileId: remoteId,
                                    fileKey: encryptedFileKeyData.base64EncodedString()))
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
        var lastId: String?
        var files = [ItemFile]()
        let itemKeys = try await keyManager.getItemKeys(userId: userId,
                                                        shareId: item.shareId,
                                                        itemId: item.itemId)
        while true {
            let response = try await remoteFileDatasource.getActiveFiles(userId: userId,
                                                                         item: item,
                                                                         lastId: lastId)
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
}

private extension PendingFileAttachment {
    var toProtobuf: FileMetadata {
        var protobuf = FileMetadata()
        protobuf.name = metadata.name
        protobuf.mimeType = metadata.mimeType
        return protobuf
    }
}
