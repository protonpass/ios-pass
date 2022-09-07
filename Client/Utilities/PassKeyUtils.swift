//
// PassKeyUtils.swift
// Proton Pass - Created on 06/09/2022.
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

public enum PassKeyUtils {
    public static func getVaultKeyPassphrase(userData: UserData,
                                             share: Share,
                                             vaultKey: VaultKey) throws -> String {
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

    private static func validateSigningKey(userData: UserData,
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

    private static func validateVaultKey(userData: UserData,
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

public extension PassKeyUtils {
    static func getItemKeyPassphrase(vaultKey: VaultKey,
                                     vaultKeyPassphrase: String,
                                     itemKey: ItemKey) throws -> String? {
        guard let decodedPassphrase = try itemKey.keyPassphrase?.base64Decode() else { return nil }
        let vaultDecryptionKey = DecryptionKey(privateKey: vaultKey.key, passphrase: vaultKeyPassphrase)
        let vaultKeyring = try Decryptor.buildPrivateKeyRing(with: [vaultDecryptionKey])
        let decryptedPassphrase = try vaultKeyring.decrypt(.init(decodedPassphrase), verifyKey: nil, verifyTime: 0)
        guard let passphrase = decryptedPassphrase.data else {
            throw CryptoError.failedToDecryptContent
        }
        return String(data: passphrase, encoding: .utf8)
    }
}
