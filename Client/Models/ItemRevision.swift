//
// ItemRevision.swift
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
import GoLibs
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_KeyManager
import ProtonCore_Login

public enum ItemState: Int16, CaseIterable {
    case active = 1
    case trashed = 2

    public var description: String {
        switch self {
        case .active:
            return "active"
        case .trashed:
            return "trashed"
        }
    }
}

public struct ItemRevisionsPaginated: Decodable {
    public let total: Int
    public let lastToken: String?
    public let revisionsData: [ItemRevision]
}

public struct ItemRevision: Decodable, Equatable {
    public let itemID: String
    public let revision: Int64
    public let contentFormatVersion: Int16
    public let keyRotation: Int64
    public let content: String

    /// Base64 encoded item key. Only for vault shares.
    public let itemKey: String?

    /// Revision state. Values: 1 = Active, 2 = Trashed
    public let state: Int16

    /// In case this item contains an alias, this is the email address for the alias
    public let aliasEmail: String?

    /// Creation time of the item
    public let createTime: Int64

    /// Time of last update of the item
    public let modifyTime: Int64

    /// Time when the item was last used
    public let lastUseTime: Int64?

    /// Creation time of this revision
    public let revisionTime: Int64

    /// Enum representation of `state`
    public var itemState: ItemState { .init(rawValue: state) ?? .active }
}

public extension ItemRevision {
    func getContentProtobuf(userData: UserData,
                            share: Share,
                            shareKeys: [ShareKey]) throws -> ItemContentProtobuf {
        #warning("Handle this")
        guard let itemKey else {
            throw PPClientError.crypto(.failedToDecryptContent)
        }

        guard let key = shareKeys.first(where: { $0.keyRotation == keyRotation }),
              let keyData = try key.key.base64Decode() else {
            throw PPClientError.crypto(.missingShareKeys)
        }

        let decryptionKeys = userData.user.keys.map {
            DecryptionKey(privateKey: .init(value: $0.privateKey),
                          passphrase: .init(value: userData.passphrases[$0.keyID] ?? ""))
        }

        let verificationKeys = userData.user.keys.map { $0.publicKey }.map { ArmoredKey(value: $0) }
        let armoredEncryptedLatestKeyContent = try CryptoUtils.armorMessage(keyData)
        let vaultKey: VerifiedData = try Decryptor.decryptAndVerify(
            decryptionKeys: decryptionKeys,
            value: .init(value: armoredEncryptedLatestKeyContent),
            verificationKeys: verificationKeys)

        guard let itemKeyData = try itemKey.base64Decode() else {
            throw PPClientError.crypto(.failedToBase64Decode)
        }

        let itemKeyTagData = "itemkey".data(using: .utf8) ?? .init()
        let itemKeySealedBox = try AES.GCM.SealedBox(combined: itemKeyData)

        let decryptedItemKeyData = try AES.GCM.open(itemKeySealedBox,
                                                    using: .init(data: vaultKey.content),
                                                    authenticating: itemKeyTagData)

        guard let contentData = try content.base64Decode() else {
            throw PPClientError.crypto(.failedToBase64Decode)
        }

        let contentTagData = "itemcontent".data(using: .utf8) ?? .init()
        let contentSealedBox = try AES.GCM.SealedBox(combined: contentData)
        let decryptedContentData = try AES.GCM.open(contentSealedBox,
                                                    using: .init(data: decryptedItemKeyData),
                                                    authenticating: contentTagData)

        return try ItemContentProtobuf(data: decryptedContentData)
    }
}
