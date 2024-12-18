//
// UpdateItemRequest.swift
// Proton Pass - Created on 19/08/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import ProtonCoreKeyManager

public struct UpdateItemRequest: Sendable {
    /// RotationID used to encrypt the item contents
    let keyRotation: Int64

    /// Last item revision existing when the item was created
    let lastRevision: Int64

    /// Encrypted item content encoded in Base64
    let content: String

    /// Version of the content format used to create the item
    let contentFormatVersion: Int16
}

public extension UpdateItemRequest {
    init(oldRevision: Item,
         key: Data,
         keyRotation: Int64,
         itemContent: any ProtobufableItemContentProtocol) throws {
        let sealedBox = try AES.GCM.seal(itemContent.data(),
                                         key: key,
                                         associatedData: .itemContent)

        guard let updatedContent = sealedBox.combined?.base64EncodedString() else {
            throw PassError.crypto(.failedToAESEncrypt)
        }

        self.init(keyRotation: keyRotation,
                  lastRevision: oldRevision.revision,
                  content: updatedContent,
                  contentFormatVersion: Int16(Constants.ContentFormatVersion.item))
    }
}

extension UpdateItemRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case keyRotation = "KeyRotation"
        case lastRevision = "LastRevision"
        case content = "Content"
        case contentFormatVersion = "ContentFormatVersion"
    }
}
