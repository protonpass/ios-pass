//
// ShareProvider.swift
// Proton Pass - Created on 18/07/2022.
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

public protocol ShareProvider: Identifiable {
    var id: String { get }

    func getVault(userData: UserData, vaultKeys: [VaultKey]) throws -> VaultProvider
}

// swiftlint:disable function_body_length
extension Share: ShareProvider {
    public var id: String { self.shareID }

    public func getVault(userData: UserData, vaultKeys: [VaultKey]) throws -> VaultProvider {
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

        let publicAddressKeys = firstAddress.keys.map { $0.publicKey }
        guard let publicKeyRing = try Decryptor.buildPublicKeyRing(armoredKeys: publicAddressKeys) else {
            throw CryptoError.failedToVerifyVault
        }

        let signingKeyValid = try validateSigningKey(userData: userData,
                                                     privateKeyRing: privateKeyRing)

        guard signingKeyValid else { throw CryptoError.failedToVerifyVault }

        let vaultPassphrase = try validateVaultKey(userData: userData,
                                                   vaultKeys: vaultKeys,
                                                   privateKeyRing: privateKeyRing)

        let plainContent = try decryptVaultContent(vaultKeys: vaultKeys,
                                                   vaultPassphrase: vaultPassphrase,
                                                   publicKeyRing: publicKeyRing)
        let vaultContent = try VaultProtobuf(data: Data(plainContent.utf8))
        return Vault(id: vaultID, name: vaultContent.name, description: vaultContent.description_p)
    }

    private func validateSigningKey(userData: UserData, privateKeyRing: CryptoKeyRing) throws -> Bool {
        // Here we have decrypted signing key but it's not used yet
        let decryptedSigningKeyPassphrase =
        try privateKeyRing.decrypt(.init(try signingKeyPassphrase?.base64Decode()),
                                   verifyKey: nil,
                                   verifyTime: 0)
        let signingKeyFingerprint = try CryptoUtils.getFingerprint(key: signingKey)
        let decodedAcceptanceSignature = try acceptanceSignature.base64Decode()

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
                                                        publicKey: signingKey.publicKey,
                                                        verifyTime: Int64(Date().timeIntervalSince1970))

        guard vaultKeyValid else { throw CryptoError.failedToVerifyVault }

        // Here we have decrypted signing key but it's not used yet
        let decryptedVaultKeyPassphrase =
        try privateKeyRing.decrypt(.init(try vaultKey.keyPassphrase?.base64Decode()),
                                   verifyKey: nil,
                                   verifyTime: 0)
        return decryptedVaultKeyPassphrase.getString()
    }

    private func decryptVaultContent(vaultKeys: [VaultKey],
                                     vaultPassphrase: String,
                                     publicKeyRing: CryptoKeyRing) throws -> String {
        guard let vaultKey = vaultKeys.first else {
            fatalError("Post MVP")
        }

        guard let content = content,
        let contentData = try content.base64Decode() else {
            throw CryptoError.failedToDecryptContent
        }

        let armoredContent = try throwing { error in
            ArmorArmorWithType(contentData,
                               "MESSAGE",
                               &error)
        }

        guard let contentEncryptedAddressSignatureData = try contentEncryptedAddressSignature.base64Decode() else {
            throw CryptoError.failedToDecryptContent
        }

        let plainContent = try Crypto().decrypt(encrypted: armoredContent,
                                                privateKey: vaultKey.key,
                                                passphrase: vaultPassphrase)

        let armoredEncryptedAddressSignature = try throwing { error in
            ArmorArmorWithType(contentEncryptedAddressSignatureData,
                               "MESSAGE",
                               &error)
        }

        let plainAddressSignature = try Crypto().decrypt(encrypted: armoredEncryptedAddressSignature,
                                                         privateKey: vaultKey.key,
                                                         passphrase: vaultPassphrase)

        let addressSignature = try throwing { error in
            CryptoNewPGPSignatureFromArmored(plainAddressSignature, &error)
        }

        try publicKeyRing.verifyDetached(CryptoNewPlainMessage(plainContent.data(using: .utf8)),
                                         signature: addressSignature,
                                         verifyTime: Int64(Date().timeIntervalSince1970))

        guard let contentEncryptedVaultSignatureData = try contentEncryptedVaultSignature.base64Decode() else {
            throw CryptoError.failedToDecryptContent
        }

        let armoredEncryptedVaultSignature = try throwing { error in
            ArmorArmorWithType(contentEncryptedVaultSignatureData,
                               "MESSAGE",
                               &error)
        }

        let plainVaultSignature = try Crypto().decrypt(encrypted: armoredEncryptedVaultSignature,
                                                       privateKey: vaultKey.key,
                                                       passphrase: vaultPassphrase)

        let vaultSignatureValid = try Crypto().verifyDetached(signature: plainVaultSignature,
                                                              plainData: Data(plainContent.utf8),
                                                              publicKey: vaultKey.key.publicKey,
                                                              verifyTime: Int64(Date().timeIntervalSince1970))

        guard vaultSignatureValid else { throw CryptoError.failedToVerifyVault }
        return plainContent
    }
}
