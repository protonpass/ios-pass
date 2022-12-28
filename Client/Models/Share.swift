//
// Share.swift
// Proton Pass - Created on 11/07/2022.
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
import GoLibs
import ProtonCore_Crypto
import ProtonCore_DataModel
import ProtonCore_KeyManager
import ProtonCore_Login
import ProtonCore_Utilities

public enum ShareType: Int16 {
    case unknown = 0
    case vault = 1
    case label = 2
    case item = 3
}

public struct Share: Decodable {
    /// ID of the share
    public let shareID: String

    /// ID of the vault this share belongs to
    public let vaultID: String

    /// User address ID that has access to this share
    public let addressID: String

    /// Type of share. 1 for vault, 2 for label and 3 for item
    public let targetType: Int16

    /// ID of the top shared object
    public let targetID: String

    /// Permissions for this share
    public let permission: Int16

    /// Base64 encoded signature of the vault signing key fingerprint
    public let acceptanceSignature: String

    /// Email that invited you to the share
    public let inviterEmail: String

    /// Base64 encoded signature of the vault signing key fingerprint by your inviter
    public let inviterAcceptanceSignature: String

    /// Armored signing key for the share.
    /// It will be a private key if the user is a share admin
    public let signingKey: String

    /// Base64 encoded encrypted passphrase to open the signing key. Only for admins.
    public let signingKeyPassphrase: String?

    /// Base64 encoded encrypted content of the share. Can be null for item shares
    public let content: String?

    /// ID for the key needed to decrypt the share.
    /// For vault shares the vault key will be used, for label shares the label keys will
    public let contentRotationID: String

    /// Base64 encoded encrypted signature of the share content done by
    /// the signer email address key, and encrypted with the vault key
    public let contentEncryptedAddressSignature: String

    /// Base64 encoded encrypted signature of the share content signed and encrypted by the vault key
    public let contentEncryptedVaultSignature: String

    /// Email address of the content's signer
    public let contentSignatureEmail: String

    /// Version of the content's format
    public let contentFormatVersion: Int16

    /// Expiration time for this share
    public let expireTime: Int64?

    /// Time of creation of this share
    public let createTime: Int64

    public var shareType: ShareType {
        .init(rawValue: targetType) ?? .unknown
    }
}

public struct PartialShare: Decodable {
    /// ID of the share
    public let shareID: String

    /// ID of the vault this share belongs to
    public let vaultID: String

    /// Type of share. 1 for vault, 2 for label and 3 for item
    public let targetType: Int16

    /// ID of the top shared object
    public let targetID: String

    /// Permissions for this share
    public let permission: Int16

    /// Base64 encoded signature of the vault signing key fingerprint
    public let acceptanceSignature: String

    /// Email that invited you to the share
    public let inviterEmail: String

    /// Base64 encoded signature of the vault signing key fingerprint by your inviter
    public let inviterAcceptanceSignature: String

    /// Expiration time for this share
    public let expireTime: Int64?

    /// Time of creation of this share
    public let createTime: Int64
}

extension Share {
    public func getVault(userData: UserData, vaultKeys: [VaultKey]) throws -> VaultProtocol {
        let addressKeys = try CryptoUtils.unlockAddressKeys(addressID: addressID, userData: userData)

//        let publicAddressKeys = firstAddress.keys.map { $0.publicKey }
//        guard let publicKeyRing = try Decryptor.buildPublicKeyRing(armoredKeys: publicAddressKeys) else {
//            throw CryptoError.failedToVerifyVault
//        }

        let signingKeyValid = try PassKeyUtils.validateSigningKey(userData: userData,
                                                                  share: self,
                                                                  addressKeys: addressKeys)

        guard signingKeyValid else { throw CryptoError.failedToVerifyVault }

        let vaultPassphrase = try PassKeyUtils.validateVaultKey(userData: userData,
                                                                share: self,
                                                                vaultKeys: vaultKeys,
                                                                addressKeys: addressKeys)

        let plainContent = try decryptVaultContent(vaultKeys: vaultKeys,
                                                   vaultPassphrase: vaultPassphrase,
                                                   addressKeys: addressKeys)
        let vaultContent = try VaultProtobuf(data: plainContent)
        return Vault(id: vaultID,
                     shareId: shareID,
                     name: vaultContent.name,
                     description: vaultContent.description_p)
    }

    private func decryptVaultContent(vaultKeys: [VaultKey],
                                     vaultPassphrase: String,
                                     addressKeys: [DecryptionKey]) throws -> Data {
        guard let vaultKey = vaultKeys.first else {
            fatalError("Post MVP")
        }

        guard let contentData = try content?.base64Decode() else {
            throw CryptoError.failedToDecryptContent
        }

        let armoredEncryptedContent = try CryptoUtils.armorMessage(contentData)

        guard let contentEncryptedAddressSignatureData = try contentEncryptedAddressSignature.base64Decode() else {
            throw CryptoError.failedToDecryptContent
        }

        let unlockedVaultKeys = try vaultKeys.map { try CryptoUtils.unlockKey($0.key,
                                                                              passphrase: vaultPassphrase) }
        let plainContent: Data =
        try ProtonCore_Crypto.Decryptor.decrypt(decryptionKeys: unlockedVaultKeys,
                                                encrypted: .init(value: armoredEncryptedContent))

        let armoredEncryptedAddressSignature =
        try CryptoUtils.armorMessage(contentEncryptedAddressSignatureData)

        let plainAddressSignature: Data =
        try ProtonCore_Crypto.Decryptor.decrypt(decryptionKeys: unlockedVaultKeys,
                                                encrypted: .init(value: armoredEncryptedAddressSignature))

        let armoredAddressSignature = try CryptoUtils.armorSignature(plainAddressSignature)

        // swiftlint:disable:next todo
        // TODO: Need to retrieve the address key of the content generator
//        try ProtonCore_Crypto.Sign.verifyDetached(signature: .init(value: armoredAddressSignature),
//                                                  plainData: plainContent,
//                                                  verifierKey: addressKeys)
        guard let contentEncryptedVaultSignatureData = try contentEncryptedVaultSignature.base64Decode() else {
            throw CryptoError.failedToDecryptContent
        }

        let armoredEncryptedVaultSignature = try CryptoUtils.armorMessage(contentEncryptedVaultSignatureData)

        let plainVaultSignature: Data =
        try ProtonCore_Crypto.Decryptor.decrypt(decryptionKeys: unlockedVaultKeys,
                                                encrypted: .init(value: armoredEncryptedVaultSignature))

        let armoredPlainVaultSignature = try CryptoUtils.armorSignature(plainVaultSignature)

        let validVaultSignature =
        try ProtonCore_Crypto.Sign.verifyDetached(signature: .init(value: armoredPlainVaultSignature),
                                                  plainData: plainContent,
                                                  verifierKey: .init(value: vaultKey.key))

        guard validVaultSignature else { throw CryptoError.failedToVerifyVault }
        return plainContent
    }
}
