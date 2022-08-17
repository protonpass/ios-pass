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
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_KeyManager
import ProtonCore_Login

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
}

extension ItemRevision {
    public func getPartialContent(userData: UserData,
                                  share: Share,
                                  vaultKeys: [VaultKey],
                                  itemKeys: [ItemKey],
                                  verifyKeys: [String]) throws -> PartialItemContent {
        guard let vaultKey = vaultKeys.first(where: { $0.rotationID == rotationID }),
              let itemKey = itemKeys.first(where: { $0.rotationID == rotationID }) else {
            throw DataError.keyNotFound(rotationId: rotationID)
        }

        let vaultKeyPassphrase = try getVaultKeypassphrase(userData: userData,
                                                           share: share,
                                                           vaultKey: vaultKey)
        let vaultDecryptionKey = DecryptionKey(privateKey: vaultKey.key, passphrase: vaultKeyPassphrase)
        let vaultKeyring = try Decryptor.buildPrivateKeyRing(with: [vaultDecryptionKey])

        let decryptedContent = try decryptField(keyring: vaultKeyring, field: content)

        let decryptedItemSignature = try decryptField(keyring: vaultKeyring, field: itemKeySignature)
        try verifyItemSignature(signature: decryptedItemSignature, itemKey: itemKey, content: decryptedContent)

        let decryptedUserSignature = try decryptField(keyring: vaultKeyring, field: userSignature)
        // swiftlint:disable:next todo
        // TODO:
        //        try verifyUserSignature(signature: decryptedUserSignature,
        //                                verifyKeys: verifyKeys,
        //                                content: decryptedContent)

        let itemProtobuf = try ItemContentProtobuf(data: decryptedContent)

        return .init(type: itemProtobuf.itemContentData.contentType,
                     title: itemProtobuf.metadata.name,
                     detail: itemProtobuf.metadata.note)
    }

    private func decryptField(keyring: CryptoKeyRing, field: String) throws -> Data {
        let decoded = try field.base64Decode()
        let decryptedMessage = try keyring.decrypt(.init(decoded), verifyKey: nil, verifyTime: 0)
        guard let data = decryptedMessage.data else {
            throw CryptoError.failedToDecryptContent
        }
        return data
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

    private func getVaultKeypassphrase(userData: UserData, share: Share, vaultKey: VaultKey) throws -> String {
        guard let firstAddress = userData.addresses.first else {
            assertionFailure("Address can not be nil")
            throw CryptoError.failedToEncrypt
        }

        let addressKeys = try firstAddress.keys.compactMap { key -> DecryptionKey? in
            guard let binKey = userData.user.keys.first?.privateKey.unArmor else { return nil }
            let passphrase = try key.passphrase(userBinKeys: [binKey],
                                                mailboxPassphrase: userData.passphrases.first?.value ?? "")
            return DecryptionKey(privateKey: key.privateKey, passphrase: passphrase)
        }
        let privateKeyRing = try Decryptor.buildPrivateKeyRing(with: addressKeys)

        let signingKeyValid = try validateSigningKey(userData: userData,
                                                     share: share,
                                                     privateKeyRing: privateKeyRing)

        guard signingKeyValid else { throw CryptoError.failedToVerifyVault }

        return try validateVaultKey(userData: userData,
                                    share: share,
                                    vaultKeys: [vaultKey],
                                    privateKeyRing: privateKeyRing)
    }

    private func validateSigningKey(userData: UserData,
                                    share: Share,
                                    privateKeyRing: CryptoKeyRing) throws -> Bool {
        // Here we have decrypted signing key but it's not used yet
        let decryptedSigningKeyPassphrase =
        try privateKeyRing.decrypt(.init(try share.signingKeyPassphrase?.base64Decode()),
                                   verifyKey: nil,
                                   verifyTime: 0)
        let signingKeyFingerprint = try CryptoUtils.getFingerprint(key: share.signingKey)
        let decodedAcceptanceSignature = try share.acceptanceSignature.base64Decode()

        let armoredDecodedAcceptanceSignature = try throwing { error in
            ArmorArmorWithType(decodedAcceptanceSignature,
                               "SIGNATURE",
                               &error)
        }

        // swiftlint:disable:next todo
        // TODO: Should pass server time
        try privateKeyRing.verifyDetached(.init(Data(signingKeyFingerprint.utf8)),
                                          signature: .init(fromArmored: armoredDecodedAcceptanceSignature),
                                          verifyTime: Int64(Date().timeIntervalSince1970))
        return true
    }

    private func validateVaultKey(userData: UserData,
                                  share: Share,
                                  vaultKeys: [VaultKey],
                                  privateKeyRing: CryptoKeyRing) throws -> String {
        guard let vaultKey = vaultKeys.first else {
            fatalError("Post MVP")
        }
        let vaultKeyFingerprint = try CryptoUtils.getFingerprint(key: vaultKey.key)
        let decodedVaultKeySignature = try vaultKey.keySignature.base64Decode()

        let armoredDecodedVaultKeySignature = try throwing { error in
            ArmorArmorWithType(decodedVaultKeySignature,
                               "SIGNATURE",
                               &error)
        }

        let vaultKeyValid = try Crypto().verifyDetached(signature: armoredDecodedVaultKeySignature,
                                                        plainData: .init(Data(vaultKeyFingerprint.utf8)),
                                                        publicKey: share.signingKey.publicKey,
                                                        verifyTime: Int64(Date().timeIntervalSince1970))

        guard vaultKeyValid else { throw CryptoError.failedToVerifyVault }

        // Here we have decrypted signing key but it's not used yet
        let decryptedVaultKeyPassphrase =
        try privateKeyRing.decrypt(.init(try vaultKey.keyPassphrase?.base64Decode()),
                                   verifyKey: nil,
                                   verifyTime: 0)
        return decryptedVaultKeyPassphrase.getString()
    }
}
