//
// CreateVault.swift
// Proton Pass - Created on 08/07/2022.
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
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_KeyManager

typealias Encryptor = ProtonCore_KeyManager.Encryptor

// swiftlint:disable identifier_name
public struct CreateVaultRequest: Encodable {
    public let AddressID: String
    public let Content: String
    public let ContentFormatVersion: Int
    public let ContentEncryptedAddressSignature: String
    public let ContentEncryptedVaultSignature: String
    public let VaultKey: String
    public let VaultKeyPassphrase: String
    public let VaultKeySignature: String
    public let KeyPacket: String
    public let KeyPacketSignature: String
    public let SigningKey: String
    public let SigningKeyPassphrase: String
    public let SigningKeyPassphraseKeyPacket: String
    public let AcceptanceSignature: String
    public let ItemKey: String
    public let ItemKeyPassphrase: String
    public let ItemKeyPassphraseKeyPacket: String
    public let ItemKeySignature: String

    public init(AddressID: String,
                Content: String,
                ContentFormatVersion: Int,
                ContentEncryptedAddressSignature: String,
                ContentEncryptedVaultSignature: String,
                VaultKey: String,
                VaultKeyPassphrase: String,
                VaultKeySignature: String,
                KeyPacket: String,
                KeyPacketSignature: String,
                SigningKey: String,
                SigningKeyPassphrase: String,
                SigningKeyPassphraseKeyPacket: String,
                AcceptanceSignature: String,
                ItemKey: String,
                ItemKeyPassphrase: String,
                ItemKeyPassphraseKeyPacket: String,
                ItemKeySignature: String) {
        self.AddressID = AddressID
        self.Content = Content
        self.ContentFormatVersion = ContentFormatVersion
        self.ContentEncryptedAddressSignature = ContentEncryptedAddressSignature
        self.ContentEncryptedVaultSignature = ContentEncryptedVaultSignature
        self.VaultKey = VaultKey
        self.VaultKeyPassphrase = VaultKeyPassphrase
        self.VaultKeySignature = VaultKeySignature
        self.KeyPacket = KeyPacket
        self.KeyPacketSignature = KeyPacketSignature
        self.SigningKey = SigningKey
        self.SigningKeyPassphrase = SigningKeyPassphrase
        self.SigningKeyPassphraseKeyPacket = SigningKeyPassphraseKeyPacket
        self.AcceptanceSignature = AcceptanceSignature
        self.ItemKey = ItemKey
        self.ItemKeyPassphrase = ItemKeyPassphrase
        self.ItemKeyPassphraseKeyPacket = ItemKeyPassphraseKeyPacket
        self.ItemKeySignature = ItemKeySignature
    }
}

public enum CreateVault {
    // swiftlint:disable:next function_body_length
    public static func create(addressId: String,
                              addressKey: Key,
                              passphrase: String,
                              vault: VaultProvider) throws -> CreateVaultRequest {
        // Generate signing key
        let (signingKey, signingKeyPassphrase) = try CryptoUtils.generateKey(name: "VaultSigningKey",
                                                                             email: "vault_signing@proton")
        let encryptedSigningKeyPassphrase = try Encryptor.encrypt(signingKeyPassphrase, key: addressKey.publicKey)
        let (signingKeyPassphraseKeyPacket, signingKeyPassphraseDataPacket) =
        try CryptoUtils.splitPGPMessage(encryptedSigningKeyPassphrase)

        let signingKeyFingerprint = try CryptoUtils.getFingerprint(key: signingKey)
        let signingKeySignature = try Encryptor.sign(list: Data(signingKeyFingerprint.utf8),
                                                     addressKey: addressKey.privateKey,
                                                     addressPassphrase: passphrase)
        // Generate vault key
        let (vaultKey, vaultKeyPassphrase) = try CryptoUtils.generateKey(name: "VaultKey",
                                                                         email: "vault@proton")
        let encryptedVaultKeyPassphrase = try Encryptor.encrypt(vaultKeyPassphrase, key: addressKey.publicKey)
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

        let vaultBase64 = try vault.data().base64EncodedString()
        let encryptedVaultBase64 = try Encryptor.encrypt(vaultBase64, key: vaultKey)
        let nameVaultKeySignature = try Encryptor.sign(list: Data(encryptedVaultBase64.utf8),
                                                       addressKey: vaultKey,
                                                       addressPassphrase: vaultKeyPassphrase)

        let signedVaultKeyPassphraseKeyPacket = try Encryptor.sign(list: vaultKeyPassphraseKeyPacket,
                                                                   addressKey: vaultKey,
                                                                   addressPassphrase: vaultKeyPassphrase)

        let nameAddressSignature = try Encryptor.sign(list: Data(vaultBase64.utf8),
                                                      addressKey: addressKey.privateKey,
                                                      addressPassphrase: passphrase)

        let encryptedNameAddressSignature = try Encryptor.encrypt(nameAddressSignature, key: vaultKey)
        let encryptedNameVaultKeySignature = try Encryptor.encrypt(nameVaultKeySignature, key: vaultKey)

        return .init(AddressID: addressId,
                     Content: try CryptoUtils.unarmorAndBase64(data: encryptedVaultBase64,
                                                               name: "encryptedVaultBase64"),
                     ContentFormatVersion: 1,
                     ContentEncryptedAddressSignature:
                        try CryptoUtils.unarmorAndBase64(data: encryptedNameAddressSignature,
                                                         name: "encryptedNameAddressSignature"),
                     ContentEncryptedVaultSignature:
                        try CryptoUtils.unarmorAndBase64(data: encryptedNameVaultKeySignature,
                                                         name: "encryptedNameVaultKeySignature"),
                     VaultKey: vaultKey,
                     VaultKeyPassphrase: vaultKeyPassphraseDataPacket.base64EncodedString(),
                     VaultKeySignature: try CryptoUtils.unarmorAndBase64(data: vaultKeySignature,
                                                                         name: "vaultKeySignature"),
                     KeyPacket: vaultKeyPassphraseKeyPacket.base64EncodedString(),
                     KeyPacketSignature:
                        try CryptoUtils.unarmorAndBase64(data: signedVaultKeyPassphraseKeyPacket,
                                                         name: "signedVaultKeyPassphraseKeyPacket"),
                     SigningKey: signingKey,
                     SigningKeyPassphrase: signingKeyPassphraseDataPacket.base64EncodedString(),
                     SigningKeyPassphraseKeyPacket: signingKeyPassphraseKeyPacket.base64EncodedString(),
                     AcceptanceSignature: try CryptoUtils.unarmorAndBase64(data: signingKeySignature,
                                                                           name: "signingKeySignature"),
                     ItemKey: itemKey,
                     ItemKeyPassphrase: itemKeyPassphraseDataPacket.base64EncodedString(),
                     ItemKeyPassphraseKeyPacket: itemKeyPassphraseKeyPacket.base64EncodedString(),
                     ItemKeySignature: try CryptoUtils.unarmorAndBase64(data: itemKeySignature,
                                                                        name: "itemKeySignature"))
    }
}
