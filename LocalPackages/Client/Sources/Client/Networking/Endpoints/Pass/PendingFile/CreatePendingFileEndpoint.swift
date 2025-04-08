//
// CreatePendingFileEndpoint.swift
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
import ProtonCoreNetworking

struct CreatePendingFileRequest: Encodable, Sendable {
    let metadata: String
    let chunkCount: Int
    let encryptionVersion: Int

    enum CodingKeys: String, CodingKey {
        case metadata = "Metadata"
        case chunkCount = "ChunkCount"
        case encryptionVersion = "EncryptionVersion"
    }
}

struct CreatePendingFileResponse: Decodable, Sendable {
    let file: RemotePendingFile
}

struct CreatePendingFileEndpoint: Endpoint {
    typealias Body = CreatePendingFileRequest
    typealias Response = CreatePendingFileResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: CreatePendingFileRequest?

    init(metadata: String, chunkCount: Int, encryptionVersion: Int) {
        debugDescription = "Create a new pending file"
        path = "/pass/v1/file"
        method = .post
        body = .init(metadata: metadata,
                     chunkCount: chunkCount,
                     encryptionVersion: encryptionVersion)
    }
}
