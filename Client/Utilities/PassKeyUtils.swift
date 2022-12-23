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

typealias DecryptionKey = ProtonCore_Crypto.DecryptionKey

public enum PassKeyUtils {
    public static func getVaultKeyPassphrase(userData: UserData,
                                             share: Share,
                                             vaultKey: VaultKey) throws -> String {
        guard let firstAddress = userData.addresses.first(where: { $0.addressID == share.addressID }) else {
            assertionFailure("Address can not be nil")
            throw CryptoError.failedToEncrypt
        }

        let addressKeys = firstAddress.keys.compactMap { key -> ProtonCore_Crypto.DecryptionKey? in
            guard let binKey = userData.user.keys.first?.privateKey.unArmor else { return nil }
            let binKeys = userData.user.keys.map { $0.privateKey }.compactMap { $0.unArmor }
            for passphrase in userData.passphrases {
                if let decryptionKeyPassphrase = try? key.passphrase(userBinKeys: [binKey],
                                                                     mailboxPassphrase: passphrase.value) {
                    return .init(privateKey: .init(value: key.privateKey),
                                 passphrase: .init(value: decryptionKeyPassphrase))
                }
            }
            return nil
        }

        let signingKeyValid = try validateSigningKey(userData: userData,
                                                     share: share,
                                                     addressKeys: addressKeys)

        guard signingKeyValid else { throw CryptoError.failedToVerifyVault }

        return try validateVaultKey(userData: userData,
                                    share: share,
                                    vaultKeys: [vaultKey],
                                    addressKeys: addressKeys)
    }

    static func validateSigningKey(userData: UserData,
                                   share: Share,
                                   addressKeys: [ProtonCore_Crypto.DecryptionKey]) throws -> Bool {
        guard let signingKeyPassphraseData = try share.signingKeyPassphrase?.base64Decode() else {
            throw CryptoError.failedToDecode
        }
        let armoredSigningKeyPassphrase = try CryptoUtils.armorMessage(signingKeyPassphraseData)
        let decryptedSigningKeyPassphrase: String =
        try ProtonCore_Crypto.Decryptor.decrypt(decryptionKeys: addressKeys,
                                                encrypted: .init(value: armoredSigningKeyPassphrase))

        // Here we have decrypted signing key but it's not used yet
        let signingKeyFingerprint = try CryptoUtils.getFingerprint(key: share.signingKey)
        guard let decodedAcceptanceSignature = try share.acceptanceSignature.base64Decode() else {
            throw CryptoError.failedToDecode
        }
        let armoredDecodedAcceptanceSignature = try CryptoUtils.armorSignature(decodedAcceptanceSignature)

        // swiftlint:disable:next todo
        // TODO: Should pass server time
        return try ProtonCore_Crypto.Sign.verifyDetached(
            signature: .init(value: armoredDecodedAcceptanceSignature),
            plainText: signingKeyFingerprint,
            verifierKeys: addressKeys.toPublicArmored(),
            verifyTime: Int64(Date().timeIntervalSince1970))
    }

    static func validateVaultKey(userData: UserData,
                                 share: Share,
                                 vaultKeys: [VaultKey],
                                 addressKeys: [ProtonCore_Crypto.DecryptionKey]) throws -> String {
        guard let vaultKey = vaultKeys.first else {
            fatalError("Post MVP")
        }
        let vaultKeyFingerprint = try CryptoUtils.getFingerprint(key: vaultKey.key)
        guard let decodedVaultKeySignature = try vaultKey.keySignature.base64Decode() else {
            throw CryptoError.failedToDecode
        }
        let armoredDecodedVaultKeySignature = try CryptoUtils.armorSignature(decodedVaultKeySignature)

        let vaultKeyValid = try ProtonCore_Crypto.Sign.verifyDetached(
            signature: .init(value: armoredDecodedVaultKeySignature),
            plainText: vaultKeyFingerprint,
            verifierKey: .init(value: share.signingKey.publicKey))

        guard vaultKeyValid else { throw CryptoError.failedToVerifyVault }

        guard let vaultKeyPassphraseData = try vaultKey.keyPassphrase?.base64Decode() else {
            throw CryptoError.failedToDecode
        }
        let armoredVaultKeyPassphrase = try CryptoUtils.armorMessage(vaultKeyPassphraseData)
        return try ProtonCore_Crypto.Decryptor.decrypt(decryptionKeys: addressKeys,
                                                       encrypted: .init(value: armoredVaultKeyPassphrase))
    }
}

public extension PassKeyUtils {
    static func getItemKeyPassphrase(vaultKey: VaultKey,
                                     vaultKeyPassphrase: String,
                                     itemKey: ItemKey) throws -> String? {
        guard let decodedPassphrase = try itemKey.keyPassphrase?.base64Decode() else { return nil }
        let armoredDecodedPassphrase = try CryptoUtils.armorMessage(decodedPassphrase)
        let vaultDecryptionKey = DecryptionKey(privateKey: .init(value: vaultKey.key),
                                               passphrase: .init(value: vaultKeyPassphrase))
        return try ProtonCore_Crypto.Decryptor.decrypt(decryptionKeys: [vaultDecryptionKey],
                                                       encrypted: .init(value: armoredDecodedPassphrase))
    }
}

extension Array where Element == ProtonCore_Crypto.DecryptionKey {
    func toPublicArmored() -> [ArmoredKey] {
        map { .init(value: $0.privateKey.armoredPublicKey) }
    }
}
