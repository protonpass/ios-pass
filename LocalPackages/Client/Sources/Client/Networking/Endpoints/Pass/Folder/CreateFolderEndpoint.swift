//
// CreateFolderEndpoint.swift
// Proton Pass - Created on 28/11/2025.
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

import Entities
import ProtonCoreNetworking

struct CreateFolderEndpoint: Endpoint {
    typealias Body = CreateItemRequest
    typealias Response = FolderResponse

    let debugDescription: String
    let path: String
    let method: HTTPMethod
    let body: CreateFolderRequest?

    init(shareId: String, request: CreateFolderRequest) {
        debugDescription = "Create folder in share with id: \(shareId)"
        path = "/pass/v1/share/\(shareId)/folder"
        method = .post
        body = request
    }
}

public struct CreateFolderRequest: Sendable, Encodable {
    public let parentFolderID: String?
    public let keyRotation: Int
    public let contentFormatVersion: Int
    public let content: String
    public let folderKey: String

    public init(parentFolderID: String?,
                keyRotation: Int,
                contentFormatVersion: Int,
                content: String,
                folderKey: String) {
        self.parentFolderID = parentFolderID
        self.keyRotation = keyRotation
        self.contentFormatVersion = contentFormatVersion
        self.content = content
        self.folderKey = folderKey
    }

    enum CodingKeys: String, CodingKey {
        case parentFolderID = "ParentFolderID"
        case keyRotation = "KeyRotation"
        case contentFormatVersion = "ContentFormatVersion"
        case content = "Content"
        case folderKey = "FolderKey"
    }
}
