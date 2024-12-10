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

public protocol FileAttachmentRepositoryProtocol: Sendable {
    func createPendingFile(userId: String,
                           file: PendingFileAttachment) async throws -> RemotePendingFile
}

public actor FileAttachmentRepository: FileAttachmentRepositoryProtocol {
    private let remoteDatasource: any RemoteFileDatasourceProtocol

    public init(remoteDatasource: any RemoteFileDatasourceProtocol) {
        self.remoteDatasource = remoteDatasource
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
}

private extension PendingFileAttachment {
    var toProtobuf: FileMetadata {
        var protobuf = FileMetadata()
        protobuf.name = metadata.name
        protobuf.mimeType = metadata.mimeType
        return protobuf
    }
}
