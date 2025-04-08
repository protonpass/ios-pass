//
// ItemFile.swift
// Proton Pass - Created on 03/12/2024.
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

public struct ItemFile: Decodable, Sendable, Equatable, Hashable {
    public let fileID: String
    public let size: Int
    public let metadata: String
    public let fileKey: String
    public let itemKeyRotation: Int
    public let chunks: [FileChunk]
    public let encryptionVersion: Int
    public let revisionAdded: Int
    public let revisionRemoved: Int?
    public let persistentFileUID: String
    public let createTime: Int
    public let modifyTime: Int

    // To be filled up once metadata is decrypted
    public var name: String?
    public var mimeType: String?

    public init(fileID: String,
                size: Int,
                metadata: String,
                fileKey: String,
                itemKeyRotation: Int,
                chunks: [FileChunk],
                encryptionVersion: Int,
                revisionAdded: Int,
                revisionRemoved: Int,
                persistentFileUID: String,
                createTime: Int,
                modifyTime: Int) {
        self.fileID = fileID
        self.size = size
        self.metadata = metadata
        self.fileKey = fileKey
        self.itemKeyRotation = itemKeyRotation
        self.chunks = chunks
        self.encryptionVersion = encryptionVersion
        self.revisionAdded = revisionAdded
        self.revisionRemoved = revisionRemoved
        self.persistentFileUID = persistentFileUID
        self.createTime = createTime
        self.modifyTime = modifyTime
    }
}

public struct FileChunk: Decodable, Sendable, Equatable, Hashable {
    public let chunkID: String
    public let index: Int
    public let size: Int
}
