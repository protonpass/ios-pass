//
// FileAttachmentReason.swift
// Proton Pass - Created on 27/11/2024.
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
//

import Foundation

public extension PassError {
    enum FileAttachmentReason: CustomDebugStringConvertible, Sendable {
        case noPngData
        case noDataFound(URL)
        case noDataForChunk(String)
        case noChunkId(String)
        case failedToProcessPickedPhotos
        case failedToEncryptFile
        case failedToUploadMissingRemoteId
        case failedToDownloadMissingFileName(String)
        case failedToDownloadMissingDecryptedFileKey(String)
        case failedToDownloadNoFetchedFiles
        case failedToAttachMissingRemoteId
        case failedToUpdateMissingMimeType
        case failedToUpload(Int)
        case fileTooLarge(UInt64)
        case missingItemKey(Int)
        case missingFile(String)

        public var debugDescription: String {
            switch self {
            case .noPngData:
                "No PNG data"
            case let .noDataFound(url):
                "No data found \(url.absoluteString)"
            case let .noDataForChunk(id):
                "No data for chunk \(id)"
            case let .noChunkId(fileId):
                "No chunk ID for file \(fileId)"
            case .failedToProcessPickedPhotos:
                "Failed to process picked photos"
            case .failedToEncryptFile:
                "Failed to encrypt file"
            case .failedToUploadMissingRemoteId:
                "Failed to upload because of missing remote ID"
            case let .failedToDownloadMissingFileName(id):
                "Failed to download because of missing file name \(id)"
            case let .failedToDownloadMissingDecryptedFileKey(id):
                "Failed to download because of missing decrypted file key \(id)"
            case .failedToDownloadNoFetchedFiles:
                "Failed to download because of missing fetched files"
            case .failedToAttachMissingRemoteId:
                "Failed to attach file to an item because of missing remote ID"
            case .failedToUpdateMissingMimeType:
                "Failed to update because of missing MIME type"
            case let .failedToUpload(code):
                "Failed to upload (\(code))"
            case let .fileTooLarge(size):
                "File too large (\(size) bytes)"
            case let .missingItemKey(rotation):
                "Missing item key rotation \(rotation)"
            case let .missingFile(id):
                "Missing file \(id)"
            }
        }
    }
}
