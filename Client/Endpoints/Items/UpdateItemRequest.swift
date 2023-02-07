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

import ProtonCore_KeyManager

public struct UpdateItemRequest {
    /// RotationID used to encrypt the item contents
    public let rotationID: String

    /// Last item revision existing when the item was created
    public let lastRevision: Int16

    /// Encrypted item content encoded in Base64
    public let content: String

    /// Version of the content format used to create the item
    public let contentFormatVersion: Int16

    /// Contents signature by the user address key encrypted with the same session key
    /// as the contents encoded in base64
    public let userSignature: String

    /// Contents signature by the item key encrypted with the same session key
    /// as the contents encoded in base64
    public let itemKeySignature: String
}

public extension UpdateItemRequest {
    init(oldRevision: ItemRevision,
         vaultKey: VaultKey,
         vaultKeyPassphrase: String,
         itemKey: ItemKey,
         itemKeyPassphrase: String,
         addressKey: AddressKey,
         itemContent: ProtobufableItemContentProtocol) throws {
        let itemContentData = try itemContent.data()

        guard let contentData = try oldRevision.content.base64Decode() else {
            throw PPClientError.crypto(.failedToDecode)
        }

        let content = try CryptoUtils.armorMessage(contentData)

        let sessionKey = try Decryptor.decryptSessionKey(of: content,
                                                         privateKey: vaultKey.key,
                                                         passphrase: vaultKeyPassphrase)
        let dataPacket = try sessionKey.encrypt(.init(itemContentData))

        let userSignature = try Encryptor.sign(list: itemContentData,
                                               addressKey: addressKey.key.privateKey,
                                               addressPassphrase: addressKey.keyPassphrase)
        let itemKeySignature = try Encryptor.sign(list: itemContentData,
                                                  addressKey: itemKey.key,
                                                  addressPassphrase: itemKeyPassphrase)

        guard let unarmoredUserSignature = userSignature.unArmor else {
            throw PPClientError.crypto(.failedToUnarmor("UserSignature"))
        }
        let encryptedUserSignature = try sessionKey.encrypt(.init(unarmoredUserSignature))

        guard let unarmoredItemKeySignature = itemKeySignature.unArmor else {
            throw PPClientError.crypto(.failedToUnarmor("ItemKeySignature"))
        }
        let encryptedItemSignature = try sessionKey.encrypt(.init(unarmoredItemKeySignature))

        self.init(rotationID: oldRevision.rotationID,
                  lastRevision: oldRevision.revision,
                  content: dataPacket.base64EncodedString(),
                  contentFormatVersion: 1,
                  userSignature: encryptedUserSignature.base64EncodedString(),
                  itemKeySignature: encryptedItemSignature.base64EncodedString())
    }
}

extension UpdateItemRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case rotationID = "RotationID"
        case lastRevision = "LastRevision"
        case content = "Content"
        case contentFormatVersion = "ContentFormatVersion"
        case userSignature = "UserSignature"
        case itemKeySignature = "ItemKeySignature"
    }
}
