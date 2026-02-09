//
// UpdateFolderEndpoint.swift
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

import Core
import CryptoKit
import Entities
import Foundation
import ProtonCoreNetworking

struct UpdateFolderEndpoint: Endpoint {
    typealias Body = UpdateFolderRequest
    typealias Response = FolderResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: UpdateFolderRequest?

    init(shareId: String, folderId: String, request: UpdateFolderRequest) {
        debugDescription = "Update folder with id: \(folderId) from share: \(shareId)"
        path = "/pass/v1/share/\(shareId)/folder/\(folderId)"
        method = .put
        body = request
    }
}

public struct UpdateFolderRequest: Sendable, Encodable {
    let content: UpdateFolderRequestPayload

    private enum CodingKeys: String, CodingKey {
        case content = "Content"
    }
}

struct UpdateFolderRequestPayload: Sendable, Encodable {
    /// RotationID used to encrypt the folder contents
    let keyRotation: Int64
    /// Encrypted folder content encoded in Base64
    let content: String
    /// Version of the content format used to create the folder
    let contentFormatVersion: Int

    init(keyRotation: Int64,
         content: String,
         contentFormatVersion: Int) {
        self.keyRotation = keyRotation
        self.content = content
        self.contentFormatVersion = contentFormatVersion
    }

    init(encryptionKey: any CryptographicKeyProtocol,
         folderContent: FolderContent) throws {
        let updatedContent = try AES.GCM.seal(folderContent.data(),
                                              key: encryptionKey.keyData,
                                              associatedData: .folderContent)

        self.init(keyRotation: encryptionKey.keyRotation,
                  content: updatedContent.base64EncodedString(),
                  contentFormatVersion: Constants.ContentFormatVersion.folder)
    }

    enum CodingKeys: String, CodingKey {
        case keyRotation = "KeyRotation"
        case content = "Content"
        case contentFormatVersion = "ContentFormatVersion"
    }
}
