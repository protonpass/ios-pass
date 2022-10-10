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
import Crypto
import CryptoKit
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_KeyManager
import ProtonCore_Login

public enum ItemState: Int16, CaseIterable {
    case active = 1
    case trashed = 2
}

public struct ItemRevisionList: Decodable {
    public let total: Int
    public let revisionsData: [ItemRevision]
}

public struct ItemRevision: Decodable {
    public let itemID: String
    public let revision: Int16
    public let contentFormatVersion: Int16

    /// Parent key ID to whom the key packet belongs
    public let rotationID: String

    /// Base64 encoded item contents including the key packet
    public let content: String

    /// Base64 encoded item contents encrypted signature made with the user's address key
    public let userSignature: String

    /// Base64 encoded item contents encrypted signature made with the vault's item key
    public let itemKeySignature: String

    /// Revision state
    public let state: Int16

    /// Email address of the signer
    public let signatureEmail: String

    /// In case this item contains an alias, this is the email address for the alias
    public let aliasEmail: String?

    // Post MVP
    //    public let labels: [String]

    /// Creation time of the item
    public let createTime: Int64

    /// Time of last update of the item
    public let modifyTime: Int64

    /// Creation time of this revision
    public let revisionTime: Int64

    /// Enum representation of `state`
    public var itemState: ItemState { .init(rawValue: state) ?? .active }
}

extension ItemRevision {
    public func getContentProtobuf(userData: UserData,
                                   share: Share,
                                   vaultKeys: [VaultKey],
                                   itemKeys: [ItemKey],
                                   verifyKeys: [String]) throws -> ItemContentProtobuf {
        guard let vaultKey = vaultKeys.first(where: { $0.rotationID == rotationID }),
              let itemKey = itemKeys.first(where: { $0.rotationID == rotationID }) else {
            throw DataError.keyNotFound(rotationId: rotationID)
        }

        let vaultKeyPassphrase = try PassKeyUtils.getVaultKeyPassphrase(userData: userData,
                                                                        share: share,
                                                                        vaultKey: vaultKey)
        let vaultDecryptionKey = DecryptionKey(privateKey: .init(value: vaultKey.key),
                                               passphrase: .init(value: vaultKeyPassphrase))

        let decryptedContent = try decryptField(decryptionKeys: [vaultDecryptionKey],
                                                field: content)

        let decryptedItemSignature = try decryptField(decryptionKeys: [vaultDecryptionKey],
                                                      field: itemKeySignature)
        try verifyItemSignature(signature: decryptedItemSignature,
                                itemKey: itemKey,
                                content: decryptedContent)

        let decryptedUserSignature = try decryptField(decryptionKeys: [vaultDecryptionKey],
                                                      field: userSignature)
        // swiftlint:disable:next todo
        // TODO:
        //        try verifyUserSignature(signature: decryptedUserSignature,
        //                                verifyKeys: verifyKeys,
        //                                content: decryptedContent)

        return try ItemContentProtobuf(data: decryptedContent)
    }

    private func decryptField(decryptionKeys: [DecryptionKey], field: String) throws -> Data {
        guard let decoded = try field.base64Decode() else {
            throw CryptoError.failedToDecode
        }
        let armoredDecoded = try CryptoUtils.armorMessage(decoded)
        return try ProtonCore_Crypto.Decryptor.decrypt(decryptionKeys: decryptionKeys,
                                                       encrypted: .init(value: armoredDecoded))
    }

    private func verifyUserSignature(signature: Data, verifyKeys: [String], content: Data) throws {
        for key in verifyKeys {
            let valid = try Crypto().verifyDetached(signature: CryptoUtils.armorSignature(signature),
                                                    plainData: content,
                                                    publicKey: key,
                                                    verifyTime: 0)
            if valid { return }
        }
        throw CryptoError.failedToVerifySignature
    }

    private func verifyItemSignature(signature: Data, itemKey: ItemKey, content: Data) throws {
        let valid = try Crypto().verifyDetached(signature: CryptoUtils.armorSignature(signature),
                                                plainData: content,
                                                publicKey: itemKey.key.publicKey,
                                                verifyTime: Int64(Date().timeIntervalSince1970))
        if !valid { throw CryptoError.failedToVerifySignature }
    }
}

public enum SymmetricallyEncryptedItemError: Error {
    case corruptedEncryptedContent
}

/// ItemRevision with its symmetrically encrypted content by an application-wide symmetric key
public struct SymmetricallyEncryptedItem {
    /// ID of the share that the item belongs to
    public let shareId: String

    /// Original item revision object as returned by the server
    public let item: ItemRevision

    /// Symmetrically encrypted content in base 64 format
    public let encryptedContent: String

    /// Whether the item is of type log in or not
    public let isLogInItem: Bool

    public func getEncryptedItemContent() throws -> ItemContent {
        guard let data = try encryptedContent.base64Decode() else {
            throw SymmetricallyEncryptedItemError.corruptedEncryptedContent
        }
        let protobufItem = try ItemContentProtobuf(data: data)
        return .init(shareId: shareId,
                     itemId: item.itemID,
                     contentProtobuf: protobufItem)
    }

    public func getDecryptedItemContent(symmetricKey: CryptoKit.SymmetricKey) throws -> ItemContent {
        guard let data = try encryptedContent.base64Decode() else {
            throw SymmetricallyEncryptedItemError.corruptedEncryptedContent
        }
        let encryptedProtobufItem = try ItemContentProtobuf(data: data)
        let decryptedProtobufItem = try encryptedProtobufItem.symmetricallyDecrypted(symmetricKey)
        return .init(shareId: shareId,
                     itemId: item.itemID,
                     contentProtobuf: decryptedProtobufItem)
    }
}
