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

import GoLibs

public struct CreateItemRequest {
    /// Encrypted ID of the VaultKey used to create this item
    public let rotationID: String

    /// Pairs of labelId:labelKeyPacket
    public let labels: [ItemLabelKeyPacket]

    /// VaultKeyPacket encoded in Base64
    public let vaultKeyPacket: String

    /// Base64 encoded signature for the vault keypacket
    public let vaultKeyPacketSignature: String

    /// Version of the content format used to create the item
    public let contentFormatVersion: Int16

    /// Encrypted item content encoded in Base64
    public let content: String

    /// Contents signature by the user address key encrypted with the same session key
    /// as the contents encoded in base64
    public let userSignature: String

    /// Contents signature by the item key encrypted with the same session key
    /// as the contents encoded in base64
    public let itemKeySignature: String
}

extension CreateItemRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case rotationID = "RotationID"
        case labels = "Labels"
        case vaultKeyPacket = "VaultKeyPacket"
        case vaultKeyPacketSignature = "VaultKeyPacketSignature"
        case contentFormatVersion = "ContentFormatVersion"
        case content = "Content"
        case userSignature = "UserSignature"
        case itemKeySignature = "ItemKeySignature"
    }
}

public extension CreateItemRequest {
    init(vaultKey: VaultKey,
         vaultKeyPassphrase: String,
         itemKey: ItemKey,
         itemKeyPassphrase: String,
         addressKey: AddressKey,
         itemContent: ProtobufableItemContentProtocol) throws {
        let itemContentData = try itemContent.data()

        let sessionKey = try CryptoUtils.generateSessionKey()
        let dataPacket = try sessionKey.encrypt(.init(itemContentData))
        let vaultKeyPacket = try Encryptor.encryptSessionKey(sessionKey,
                                                             withKey: vaultKey.key.publicKey)

        let userSignature = try Encryptor.sign(list: itemContentData,
                                               addressKey: addressKey.key.privateKey,
                                               addressPassphrase: addressKey.keyPassphrase)

        guard let decodedVaultKeyPacket = try vaultKeyPacket.base64Decode() else {
            throw PPClientError.crypto(.failedToDecode)
        }

        let vaultKeyPacketSignature = try Encryptor.sign(list: decodedVaultKeyPacket,
                                                         addressKey: itemKey.key,
                                                         addressPassphrase: itemKeyPassphrase)

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

        guard let unarmoredVaultKeyPacketSignature = vaultKeyPacketSignature.unArmor else {
            throw PPClientError.crypto(.failedToUnarmor("VaultKeyPacketSignature"))
        }

        self.init(rotationID: vaultKey.rotationID,
                  labels: [],
                  vaultKeyPacket: vaultKeyPacket,
                  vaultKeyPacketSignature: unarmoredVaultKeyPacketSignature.base64EncodedString(),
                  contentFormatVersion: 1,
                  content: dataPacket.base64EncodedString(),
                  userSignature: encryptedUserSignature.base64EncodedString(),
                  itemKeySignature: encryptedItemSignature.base64EncodedString())
    }
}
