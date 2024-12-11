//
// UploadFileChunkEndpoint.swift
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
import ProtonCoreNetworking

struct UploadFileChunkRequest: Encodable, Sendable {
    let chunkIndex: Int
    let chunkData: Data

    enum CodingKeys: String, CodingKey {
        case chunkIndex = "ChunkIndex"
        case chunkData = "ChunkData"
    }
}

struct UploadFileChunkEndpoint: Endpoint {
    typealias Body = UploadFileChunkRequest
    typealias Response = CodeOnlyResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: UploadFileChunkRequest?

    init(fileId: String, data: Data) {
        debugDescription = "Upload chunk for pending file"
        path = "/pass/v1/file/\(fileId)/chunk"
        method = .post
        body = .init(chunkIndex: 0, chunkData: data)
    }
}
