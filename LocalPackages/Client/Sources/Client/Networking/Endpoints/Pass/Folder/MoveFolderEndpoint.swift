//
// MoveFolderEndpoint.swift
// Proton Pass - Created on 01/12/2025.
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

// swiftlint:disable:next todo
// TODO: remove with folder implementation
// periphery:ignore:all

import CryptoKit
import Entities
import Foundation
import ProtonCoreNetworking

public struct MoveFolderRequest: Encodable, Sendable {
    /// Encrypted ID of the destination share
    let parentFolderID: String
    let folderKeys: [FolderKey]

    enum CodingKeys: String, CodingKey {
        case parentFolderID = "ParentFolderID"
        case folderKeys = "FolderKeys"
    }
}

struct MoveFolderEndpoint: Endpoint {
    typealias Body = MoveFolderRequest
    typealias Response = FolderResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: MoveFolderRequest?

    init(request: MoveFolderRequest, from shareId: String, folderId: String) {
        debugDescription = "Move folder from share: \(shareId) to folder: \(folderId)"
        path = "/pass/v1/share/\(shareId)/folder/\(folderId)/move"
        method = .put
        body = request
    }
}
