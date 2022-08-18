//
// CreateVaultRequest.swift
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

import Crypto
import ProtonCore_DataModel

public struct CreateVaultRequest: Encodable {
    /// Encrypted ID of the address that created the vault
    let addressID: String

    /// Content of the vault information encrypted with the Vault public key encoded in Base64
    let content: String

    /// Version of the format of the vault content
    let contentFormatVersion: Int

    /// Base64 encoded content signature with the user's address key
    let contentEncryptedAddressSignature: String

    /// Base64 encoded content signature with the vault key
    let contentEncryptedVaultSignature: String

    /// Armored vault key locked with the passphrase contained in the VaultKeyPassphrase
    let vaultKey: String

    /// Encrypted passphrase to decrypt the vault key
    let vaultKeyPassphrase: String

    /// Base64 encoded signature of the vault key sha256 primary fingerprint.
    /// Signed with the vault signing key
    let vaultKeySignature: String

    /// SessionKey for the passphrase encrypted with the key of the addressID. Encoded in Base64
    let keyPacket: String

    /// Base64 encoded signature of the unencoded key packet signed by the vault key
    let keyPacketSignature: String

    /// Armored signing key locked with the passphrase contained in the SigningKeyPassphrase
    let signingKey: String

    /// Base64 encoded encrypted passphrase for the signing key
    let signingKeyPassphrase: String

    /// Base64 encoded SessionKey for the encrypted signing key passphrase encrypted with the key of the addressID
    let signingKeyPassphraseKeyPacket: String

    /// Base64 encoded signature of the signing key sha256 primary fingerprint.
    /// Signed with the private key of the addressID
    let acceptanceSignature: String

    /// Armored item key locked with the passphrase contained in the ItemKeyPassphrase
    let itemKey: String

    /// Base64 encoded encrypted passphrase for the item key
    let itemKeyPassphrase: String

    /// Base64 encoded SessionKey for the encrypted item key passphrase encrypted with the vault key
    let itemKeyPassphraseKeyPacket: String

    /// Base64 encoded signature of the item key sha256 primary fingerprint, signed with the vault signing key
    let itemKeySignature: String
}

extension CreateVaultRequest {
    public init(addressKey: AddressKey, name: String, description: String) throws {
        let vault = VaultProtobuf(name: name, description: description)
        try self.init(addressKey: addressKey, vault: vault)
    }

    // swiftlint:disable:next function_body_length
    private init(addressKey: AddressKey, vault: ProtobufableVaultProtocol) throws {
        // Generate signing key
        let (signingKey, signingKeyPassphrase) = try CryptoUtils.generateKey(name: "VaultSigningKey",
                                                                             email: "vault_signing@proton")
        let encryptedSigningKeyPassphrase = try Encryptor.encrypt(signingKeyPassphrase,
                                                                  key: addressKey.key.publicKey)
        let (signingKeyPassphraseKeyPacket, signingKeyPassphraseDataPacket) =
        try CryptoUtils.splitPGPMessage(encryptedSigningKeyPassphrase)

        let signingKeyFingerprint = try CryptoUtils.getFingerprint(key: signingKey)
        let signingKeySignature = try Encryptor.sign(list: Data(signingKeyFingerprint.utf8),
                                                     addressKey: addressKey.key.privateKey,
                                                     addressPassphrase: addressKey.keyPassphrase)
        // Generate vault key
        let (vaultKey, vaultKeyPassphrase) = try CryptoUtils.generateKey(name: "VaultKey",
                                                                         email: "vault@proton")
        let encryptedVaultKeyPassphrase = try Encryptor.encrypt(vaultKeyPassphrase,
                                                                key: addressKey.key.publicKey)
        let (vaultKeyPassphraseKeyPacket, vaultKeyPassphraseDataPacket) =
        try CryptoUtils.splitPGPMessage(encryptedVaultKeyPassphrase)

        let vaultKeyFingerprint = try CryptoUtils.getFingerprint(key: vaultKey)
        let vaultKeySignature = try Encryptor.sign(list: Data(vaultKeyFingerprint.utf8),
                                                   addressKey: signingKey,
                                                   addressPassphrase: signingKeyPassphrase)

        // Generate item key
        let (itemKey, itemKeyPassphrase) = try CryptoUtils.generateKey(name: "ItemKey",
                                                                       email: "item@proton")
        let encryptedItemKeyPassphrase = try Encryptor.encrypt(itemKeyPassphrase, key: vaultKey)
        let (itemKeyPassphraseKeyPacket, itemKeyPassphraseDataPacket) =
        try CryptoUtils.splitPGPMessage(encryptedItemKeyPassphrase)

        let itemKeyFingerprint = try CryptoUtils.getFingerprint(key: itemKey)
        let itemKeySignature = try Encryptor.sign(list: Data(itemKeyFingerprint.utf8),
                                                  addressKey: signingKey,
                                                  addressPassphrase: signingKeyPassphrase)

        guard let keyRing = CryptoKeyRing(.init(fromArmored: vaultKey.publicKey)) else {
            throw CryptoError.failedToGenerateKeyRing
        }

        let vaultData = try vault.data()
        guard let encryptedVaultData = try keyRing.encrypt(.init(vaultData), privateKey: nil).data else {
            throw CryptoError.failedToEncrypt
        }
        let nameVaultKeySignature = try Encryptor.sign(list: vaultData,
                                                       addressKey: vaultKey,
                                                       addressPassphrase: vaultKeyPassphrase)

        let signedVaultKeyPassphraseKeyPacket = try Encryptor.sign(list: vaultKeyPassphraseKeyPacket,
                                                                   addressKey: vaultKey,
                                                                   addressPassphrase: vaultKeyPassphrase)

        let nameAddressSignature = try Encryptor.sign(list: vaultData,
                                                      addressKey: addressKey.key.privateKey,
                                                      addressPassphrase: addressKey.keyPassphrase)

        let encryptedNameAddressSignature = try Encryptor.encrypt(nameAddressSignature, key: vaultKey)
        let encryptedNameVaultKeySignature = try Encryptor.encrypt(nameVaultKeySignature, key: vaultKey)

        self = .init(addressID: addressKey.addressId,
                     content: encryptedVaultData.base64EncodedString(),
                     contentFormatVersion: 1,
                     contentEncryptedAddressSignature:
                        try CryptoUtils.unarmorAndBase64(data: encryptedNameAddressSignature,
                                                         name: "encryptedNameAddressSignature"),
                     contentEncryptedVaultSignature:
                        try CryptoUtils.unarmorAndBase64(data: encryptedNameVaultKeySignature,
                                                         name: "encryptedNameVaultKeySignature"),
                     vaultKey: vaultKey,
                     vaultKeyPassphrase: vaultKeyPassphraseDataPacket.base64EncodedString(),
                     vaultKeySignature: try CryptoUtils.unarmorAndBase64(data: vaultKeySignature,
                                                                         name: "vaultKeySignature"),
                     keyPacket: vaultKeyPassphraseKeyPacket.base64EncodedString(),
                     keyPacketSignature:
                        try CryptoUtils.unarmorAndBase64(data: signedVaultKeyPassphraseKeyPacket,
                                                         name: "signedVaultKeyPassphraseKeyPacket"),
                     signingKey: signingKey,
                     signingKeyPassphrase: signingKeyPassphraseDataPacket.base64EncodedString(),
                     signingKeyPassphraseKeyPacket: signingKeyPassphraseKeyPacket.base64EncodedString(),
                     acceptanceSignature: try CryptoUtils.unarmorAndBase64(data: signingKeySignature,
                                                                           name: "signingKeySignature"),
                     itemKey: itemKey,
                     itemKeyPassphrase: itemKeyPassphraseDataPacket.base64EncodedString(),
                     itemKeyPassphraseKeyPacket: itemKeyPassphraseKeyPacket.base64EncodedString(),
                     itemKeySignature: try CryptoUtils.unarmorAndBase64(data: itemKeySignature,
                                                                        name: "itemKeySignature"))
    }
}
