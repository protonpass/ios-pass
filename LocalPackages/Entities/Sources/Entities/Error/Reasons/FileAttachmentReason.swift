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
        case failedToProcessPickedPhotos
        case failedToEncryptMetadata
        case failedToEncryptFile
        case failedToUploadMissingRemoteId
        case failedToUploadMissingEncryptedData
        case fileTooLarge(UInt64)

        public var debugDescription: String {
            switch self {
            case .noPngData:
                "No PNG data"
            case let .noDataFound(url):
                "No data found \(url.absoluteString)"
            case .failedToProcessPickedPhotos:
                "Failed to process picked photos"
            case .failedToEncryptMetadata:
                "Failed to encrypt metadata"
            case .failedToEncryptFile:
                "Failed to encrypt file"
            case .failedToUploadMissingRemoteId:
                "Failed to upload because of missing remote ID"
            case .failedToUploadMissingEncryptedData:
                "Failed to upload because of missing encrypted data"
            case let .fileTooLarge(size):
                "File too large (\(size) bytes)"
            }
        }
    }
}
