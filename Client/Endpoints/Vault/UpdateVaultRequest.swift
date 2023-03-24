//
// UpdateVaultRequest.swift
// Proton Pass - Created on 24/03/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import CryptoKit
import GoLibs
import ProtonCore_Crypto
import ProtonCore_Login

public struct UpdateVaultRequest {
    /// Vault content protocol buffer data encrypted with the vault key
    /// >= 28 characters
    let content: String

    /// Version of the format of the vault content
    let contentFormatVersion: Int

    /// Key rotation used to encrypt the content
    /// > 0
    let keyRotation: Int
}

public extension UpdateVaultRequest {
    init(vault: VaultProtobuf,
         shareKey: DecryptedShareKey,
         userData: UserData) throws {
        contentFormatVersion = 1

        guard let userKey = userData.user.keys.first else {
            throw PPClientError.crypto(.missingUserKey(userID: userData.user.ID))
        }

        guard let passphrase = userData.passphrases[userKey.keyID] else {
            throw PPClientError.crypto(.missingPassphrase(keyID: userKey.keyID))
        }

        let publicKey = ArmoredKey(value: userKey.publicKey)
        let privateKey = ArmoredKey(value: userKey.privateKey)
        let signerKey = SigningKey(privateKey: privateKey,
                                   passphrase: .init(value: passphrase))

        let vaultKey = shareKey.keyData
        let encryptedVaultKeyData = try Encryptor.encrypt(publicKey: publicKey,
                                                          clearData: vaultKey,
                                                          signerKey: signerKey)

        let encryptedContent = try AES.GCM.seal(vault.data(),
                                                key: vaultKey,
                                                associatedData: .vaultcontent)

        guard let content = encryptedContent.combined?.base64EncodedString(), content.count >= 28 else {
            throw PPClientError.crypto(.failedToAESEncrypt)
        }
        self.content = content
        self.keyRotation = Int(shareKey.keyRotation)
    }
}

extension UpdateVaultRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case content = "Content"
        case contentFormatVersion = "ContentFormatVersion"
        case keyRotation = "KeyRotation"
    }
}
