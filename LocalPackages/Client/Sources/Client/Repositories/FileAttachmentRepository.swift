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
}

public actor FileAttachmentRepository: FileAttachmentRepositoryProtocol {
    private let remoteDatasource: any RemoteFileDatasourceProtocol
    private let apiServiceLite: any ApiServiceLiteProtocol

    public init(remoteDatasource: any RemoteFileDatasourceProtocol,
                apiServiceLite: any ApiServiceLiteProtocol) {
        self.remoteDatasource = remoteDatasource
        self.apiServiceLite = apiServiceLite
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
        return try await remoteDatasource.createPendingFile(userId: userId,
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
}

private extension PendingFileAttachment {
    var toProtobuf: FileMetadata {
        var protobuf = FileMetadata()
        protobuf.name = metadata.name
        protobuf.mimeType = metadata.mimeType
        return protobuf
    }
}
