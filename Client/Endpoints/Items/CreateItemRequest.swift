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

import CryptoKit
import GoLibs
import ProtonCore_Crypto
import ProtonCore_Login

public struct CreateItemRequest {
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

public extension CreateItemRequest {
    init(userData: UserData, shareKeys: [PassKey], itemContent: ProtobufableItemContentProtocol) throws {
        let latestKey = try shareKeys.latestKey()
        guard let latestKeyData = try shareKeys.latestKey().key.base64Decode() else {
            throw PPClientError.crypto(.failedToBase64Decode)
        }

        let decryptionKeys = userData.user.keys.map {
            DecryptionKey(privateKey: .init(value: $0.privateKey),
                          passphrase: .init(value: userData.passphrases[$0.keyID] ?? ""))
        }

        let verificationKeys = userData.user.keys.map { $0.publicKey }.map { ArmoredKey(value: $0) }
        let armoredEncryptedLatestKeyContent = try CryptoUtils.armorMessage(latestKeyData)
        let vaultKey: VerifiedData = try Decryptor.decryptAndVerify(
            decryptionKeys: decryptionKeys,
            value: .init(value: armoredEncryptedLatestKeyContent),
            verificationKeys: verificationKeys)

        let itemKey = PassKeyUtils.randomKey()
        let tagData = "itemcontent".data(using: .utf8) ?? .init()
        let encryptedContent = try AES.GCM.seal(itemContent.data(),
                                                using: .init(data: itemKey),
                                                authenticating: tagData)

        guard let content = encryptedContent.combined?.base64EncodedString() else {
            throw PPClientError.crypto(.failedToAESEncrypt)
        }

        let itemKeyTag = "itemkey".data(using: .utf8) ?? .init()
        let encryptedItemKey = try AES.GCM.seal(itemKey,
                                                using: .init(data: vaultKey.content),
                                                authenticating: itemKeyTag).combined ?? .init()

        self.init(keyRotation: latestKey.keyRotation,
                  contentFormatVersion: 1,
                  content: content,
                  itemKey: encryptedItemKey.base64EncodedString())
    }
}
