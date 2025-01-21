//
// RestoreFileEndpoint.swift
// Proton Pass - Created on 21/01/2025.
// Copyright (c) 2025 Proton Technologies AG
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

struct RestoreFileRequest: Encodable {
    let fileKey: String
    let itemKeyRotation: Int
}

struct RestoreFileResponse: Decodable {
    let result: RestoreFileResult
}

struct RestoreFileResult: Decodable {
    let item: Item
    let file: ItemFile
}

struct RestoreFileEndpoint: Endpoint {
    typealias Body = RestoreFileRequest
    typealias Response = RestoreFileResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: RestoreFileRequest?

    init(shareId: String,
         itemId: String,
         fileId: String,
         fileKey: String,
         itemKeyRotation: Int) {
        debugDescription = "Restore file"
        path = "/pass/v1/share/\(shareId)/item/\(itemId)/file/\(fileId)/restore"
        method = .post
        body = .init(fileKey: fileId, itemKeyRotation: itemKeyRotation)
    }
}
