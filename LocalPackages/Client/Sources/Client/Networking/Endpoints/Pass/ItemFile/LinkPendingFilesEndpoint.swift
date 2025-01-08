//
// LinkPendingFilesEndpoint.swift
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

struct LinkPendingFilesResponse: Decodable, Sendable {
    let item: Item
}

struct LinkPendingFilesRequest: Encodable, Sendable {
    let itemRevision: Int64
    let filesToAdd: [FileToAdd]
    let filesToRemove: [String]

    enum CodingKeys: String, CodingKey {
        case itemRevision = "ItemRevision"
        case filesToAdd = "FilesToAdd"
        case filesToRemove = "FilesToRemove"
    }
}

public struct FileToAdd: Encodable, Sendable {
    let fileId: String
    let fileKey: String

    enum CodingKeys: String, CodingKey {
        case fileId = "FileID"
        case fileKey = "FileKey"
    }
}

struct LinkPendingFilesEndpoint: Endpoint {
    typealias Body = LinkPendingFilesRequest
    typealias Response = LinkPendingFilesResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: LinkPendingFilesRequest?

    init(item: SymmetricallyEncryptedItem,
         filesToAdd: [FileToAdd],
         fileIdsToRemove: [String]) {
        debugDescription = "Link pending files to item"
        path = "/pass/v1/share/\(item.shareId)/item/\(item.itemId)/link_files"
        method = .post
        body = .init(itemRevision: item.item.revision,
                     filesToAdd: filesToAdd,
                     filesToRemove: fileIdsToRemove)
    }
}
