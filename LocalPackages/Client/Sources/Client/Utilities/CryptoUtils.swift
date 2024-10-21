//
// CryptoUtils.swift
// Proton Pass - Created on 12/07/2022.
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
import Entities
import Foundation
@preconcurrency import ProtonCoreCrypto
@preconcurrency import ProtonCoreCryptoGoInterface
import ProtonCoreDataModel
import ProtonCoreLogin

public enum CryptoUtils {
    // periphery:ignore
    public static func generateKey(name: String, email: String) throws -> (String, String) {
        let keyPassphrase = String.random(length: 32)
        let key = try throwing { error in
            CryptoGo.HelperGenerateKey(name,
                                       email,
                                       Data(keyPassphrase.utf8),
                                       "x25519",
                                       0,
                                       &error)
        }
        return (key, keyPassphrase)
    }

    public static func armorMessage(_ message: Data) throws -> String {
        try throwing { error in
            CryptoGo.ArmorArmorWithType(message, "MESSAGE", &error)
        }
    }

    public static func unlockAddressKeys(address: Address,
                                         userData: UserData) throws -> [ProtonCoreCrypto.DecryptionKey] {
        address.keys.compactMap { key -> DecryptionKey? in
            let binKeys = userData.user.keys.map(\.privateKey).compactMap(\.unArmor)
            for passphrase in userData.passphrases {
                if let decryptionKeyPassphrase = try? key.passphrase(userBinKeys: binKeys,
                                                                     mailboxPassphrase: passphrase.value) {
                    return .init(privateKey: .init(value: key.privateKey),
                                 passphrase: .init(value: decryptionKeyPassphrase))
                }
            }
            return nil
        }
    }

    public static func unlockAddressKeys(addressID: String,
                                         userData: UserData) throws -> [ProtonCoreCrypto.DecryptionKey] {
        guard let firstAddress = userData.addresses.first(where: { $0.addressID == addressID }) else {
            throw PassError.crypto(.addressNotFound(addressID: addressID))
        }

        return try CryptoUtils.unlockAddressKeys(address: firstAddress, userData: userData)
    }

    public static func encryptKeyForSharing(addressId: String,
                                            publicReceiverKey: PublicKey,
                                            userData: UserData,
                                            vaultKey: DecryptedShareKey) throws -> ItemKey {
        guard let addressKey = try CryptoUtils.unlockAddressKeys(addressID: addressId,
                                                                 userData: userData).first else {
            throw PassError.crypto(.addressNotFound(addressID: addressId))
        }

        let publicKey = ArmoredKey(value: publicReceiverKey.value)
        let signerKey = SigningKey(privateKey: addressKey.privateKey,
                                   passphrase: addressKey.passphrase)
        let context = SignatureContext(value: Constants.existingUserSharingSignatureContext,
                                       isCritical: true)

        let encryptedVaultKeyString = try Encryptor.encrypt(publicKey: publicKey,
                                                            clearData: vaultKey.keyData,
                                                            signerKey: signerKey,
                                                            signatureContext: context)
            .unArmor().value.base64EncodedString()

        return ItemKey(key: encryptedVaultKeyString, keyRotation: vaultKey.keyRotation)
    }
}
