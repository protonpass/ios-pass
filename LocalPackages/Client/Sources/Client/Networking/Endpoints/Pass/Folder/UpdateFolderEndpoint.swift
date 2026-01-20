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

// swiftlint:disable:next todo
// TODO: remove with folder implementation
// periphery:ignore:all

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
    /// RotationID used to encrypt the item contents
    let keyRotation: Int64

    /// Encrypted item content encoded in Base64
    let content: String

    /// Version of the content format used to create the item
    let contentFormatVersion: Int

    public init(keyRotation: Int64,
                content: String,
                contentFormatVersion: Int) {
        self.keyRotation = keyRotation
        self.content = content
        self.contentFormatVersion = contentFormatVersion
    }

    public init(encryptionKey: any CryptographicKeyProtocol,
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

// public extension UpdateFolderRequest {
//    init(folderContent: FolderContent, encryptionKey: any CryptographicKeyProtocol) throws {
//        contentFormatVersion = Constants.ContentFormatVersion.folder
//        let folderKey = encryptionKey.keyData
//
//        let encryptedContent = try AES.GCM.seal(folderContent.data(),
//                                                key: folderKey,
//                                                associatedData: .folderContent)
//        let base64Content = encryptedContent.base64EncodedString()
//        guard base64Content.count >= 28 else {
//            throw PassError.crypto(.failedToAESEncrypt)
//        }
//        content = base64Content
//        keyRotation = encryptionKey.keyRotation
//    }
// }
