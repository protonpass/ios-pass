//
// UpdateFileMetadataEndpoint.swift
// Proton Pass - Created on 12/12/2024.
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

struct UpdateFileMetadataRequest: Encodable, Sendable {
    let metadata: String

    enum CodingKeys: String, CodingKey {
        case metadata = "Metadata"
    }
}

struct UpdateFileMetadataResponse: Decodable, Sendable {
    let file: ItemFile
}

struct UpdateFileMetadataEndpoint: Endpoint {
    typealias Body = UpdateFileMetadataRequest
    typealias Response = UpdateFileMetadataResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: UpdateFileMetadataRequest?

    init(item: any ItemIdentifiable, fileId: String, metadata: String) {
        debugDescription = "Update file metadata"
        path = "/pass/v1/share/\(item.shareId)/item/\(item.itemId)/file/\(fileId)/metadata"
        method = .put
        body = .init(metadata: metadata)
    }
}
