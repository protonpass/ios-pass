//
// CreateItemRequest.swift
// Proton Pass - Created on 13/08/2022.
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

public struct CreateItemRequest: Sendable {
    /// Encrypted ID of the VaultKey used to create this item
    /// Must be >= 1
    public let keyRotation: Int64

    /// Version of the content format used to create the item
    /// Must be >= 1
    public let contentFormatVersion: Int16

    /// Encrypted item content encoded in Base64
    public let content: String

    /// Item key encrypted with the VaultKey, contents encoded in base64
    public let itemKey: String
}

extension CreateItemRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case keyRotation = "KeyRotation"
        case contentFormatVersion = "ContentFormatVersion"
        case content = "Content"
        case itemKey = "ItemKey"
    }
}

extension CreateItemRequest {
    init(vaultKey: DecryptedShareKey, itemContent: any ProtobufableItemContentProtocol) throws {
        let itemKey = try Data.random()
        let encryptedContent = try AES.GCM.seal(itemContent.data(),
                                                key: itemKey,
                                                associatedData: .itemContent)

        let encryptedItemKey = try AES.GCM.seal(itemKey,
                                                key: vaultKey.keyData,
                                                associatedData: .itemKey)

        self.init(keyRotation: vaultKey.keyRotation,
                  contentFormatVersion: Int16(Constants.ContentFormatVersion.item),
                  content: encryptedContent.base64EncodedString(),
                  itemKey: encryptedItemKey.base64EncodedString())
    }
}
