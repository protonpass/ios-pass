//
// PendingFileAttachment.swift
// Proton Pass - Created on 19/11/2024.
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

public struct PendingFileAttachment: Sendable, Equatable, Identifiable {
    /// A local unique random ID attributed to a file when it's added
    public let id: String
    public var remoteId: String?
    /// Random AES256-GCM key
    public let key: Data
    public var uploadState: FileAttachmentUploadState = .uploading(0.0)
    public var metadata: Metadata

    public init(id: String, key: Data, metadata: Metadata) {
        self.id = id
        self.key = key
        self.metadata = metadata
    }
}

public extension PendingFileAttachment {
    struct Metadata: Sendable, Equatable {
        /// The local path to the unencrypted file
        public let url: URL
        public var name: String
        public let mimeType: String
        public let fileGroup: FileGroup
        public let size: UInt64
        /// Localized formatted size for display (eg. 1 B, 2 KB, 3 MB...)
        public let formattedSize: String?

        public init(url: URL,
                    mimeType: String,
                    fileGroup: FileGroup,
                    size: UInt64,
                    formattedSize: String?) {
            self.url = url
            name = url.lastPathComponent
            self.mimeType = mimeType
            self.fileGroup = fileGroup
            self.size = size
            self.formattedSize = formattedSize
        }
    }
}
