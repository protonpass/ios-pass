//
// RemoteFileDatasource.swift
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

import Entities
import Foundation

public protocol RemoteFileDatasourceProtocol: Sendable {
    func createPendingFile(userId: String, metadata: String) async throws -> RemotePendingFile
    func updatePendingFileMetadata(userId: String,
                                   fileId: String,
                                   metadata: String) async throws -> Bool
    func updateFileMetadata(userId: String,
                            item: any ItemIdentifiable,
                            fileId: String,
                            metadata: String) async throws -> ItemFile
    func linkFilesToItem(userId: String,
                         item: SymmetricallyEncryptedItem,
                         filesToAdd: [FileToAdd],
                         fileIdsToRemove: [String]) async throws
    func getActiveFiles(userId: String,
                        item: any ItemIdentifiable,
                        lastId: String?) async throws -> PaginatedActiveItemFiles
    func getChunkContent(userId: String,
                         item: any ItemIdentifiable,
                         fileId: String,
                         chunkId: String) async throws -> Data
}

public final class RemoteFileDatasource:
    RemoteDatasource, RemoteFileDatasourceProtocol, @unchecked Sendable {}

public extension RemoteFileDatasource {
    func createPendingFile(userId: String, metadata: String) async throws -> RemotePendingFile {
        let endpoint = CreatePendingFileEndpoint(metadata: metadata)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.file
    }

    func updatePendingFileMetadata(userId: String,
                                   fileId: String,
                                   metadata: String) async throws -> Bool {
        let endpoint = UpdatePendingFileEndpoint(fileId: fileId, metadata: metadata)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.isSuccessful
    }

    func updateFileMetadata(userId: String,
                            item: any ItemIdentifiable,
                            fileId: String,
                            metadata: String) async throws -> ItemFile {
        let endpoint = UpdateFileMetadataEndpoint(item: item,
                                                  fileId: fileId,
                                                  metadata: metadata)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.file
    }

    func linkFilesToItem(userId: String,
                         item: SymmetricallyEncryptedItem,
                         filesToAdd: [FileToAdd],
                         fileIdsToRemove: [String]) async throws {
        let endpoint = LinkPendingFilesEndpoint(item: item,
                                                filesToAdd: filesToAdd,
                                                fileIdsToRemove: fileIdsToRemove)
        _ = try await exec(userId: userId, endpoint: endpoint)
    }

    func getActiveFiles(userId: String,
                        item: any ItemIdentifiable,
                        lastId: String?) async throws -> PaginatedActiveItemFiles {
        let endpoint = GetActiveItemFilesEndpoint(item: item, lastId: lastId)
        let response = try await exec(userId: userId, endpoint: endpoint)
        return response.files
    }

    func getChunkContent(userId: String,
                         item: any ItemIdentifiable,
                         fileId: String,
                         chunkId: String) async throws -> Data {
        let endpoint = GetChunkContentEndpoint(shareId: item.shareId,
                                               itemId: item.itemId,
                                               fileId: fileId,
                                               chunkId: chunkId)
        let response = try await execExpectingData(userId: userId, endpoint: endpoint)

        switch response.httpCode {
        case 200, 204:
            if let data = response.data {
                return data
            } else {
                throw PassError.fileAttachment(.noDataForChunk(chunkId))
            }

        default:
            throw PassError.network(.unexpectedHttpStatusCode(response.httpCode))
        }
    }
}
