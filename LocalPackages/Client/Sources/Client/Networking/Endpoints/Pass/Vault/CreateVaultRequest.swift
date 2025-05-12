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

import Core
import CryptoKit
import Entities
import Foundation
import ProtonCoreCrypto
import ProtonCoreLogin

public struct CreateVaultRequest: Sendable {
    /// AddressID that should be displayed as the owner
    let addressID: String

    /// Vault content protocol buffer data encrypted with the vault key
    /// >= 28 characters
    let content: String

    /// Version of the format of the vault content
    let contentFormatVersion: Int

    /// Vault key encrypted and signed with the primary user key
    /// >= 28 characters
    let encryptedVaultKey: String
}

public extension CreateVaultRequest {
    init(userData: UserData, vault: VaultContent) throws {
        contentFormatVersion = Constants.ContentFormatVersion.vault
        addressID = userData.addresses.first?.addressID ?? ""

        guard let userKey = userData.user.keys.first(where: { $0.active == 1 }) else {
            throw PassError.crypto(.missingUserKey(userID: userData.user.ID))
        }

        guard let passphrase = userData.passphrases[userKey.keyID] else {
            throw PassError.crypto(.missingPassphrase(keyID: userKey.keyID))
        }

        let publicKey = ArmoredKey(value: userKey.publicKey)
        let privateKey = ArmoredKey(value: userKey.privateKey)
        let signerKey = SigningKey(privateKey: privateKey,
                                   passphrase: .init(value: passphrase))

        let vaultKey = try Data.random()
        let encryptedVaultKeyData = try Encryptor.encrypt(publicKey: publicKey,
                                                          clearData: vaultKey,
                                                          signerKey: signerKey)
        encryptedVaultKey = try encryptedVaultKeyData.unArmor().value.base64EncodedString()

        let encryptedContent = try AES.GCM.seal(vault.data(),
                                                key: vaultKey,
                                                associatedData: .vaultContent)
        let base64Content = encryptedContent.base64EncodedString()
        guard base64Content.count >= 28 else {
            throw PassError.crypto(.failedToAESEncrypt)
        }
        content = base64Content
    }
}

extension CreateVaultRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case addressID = "AddressID"
        case content = "Content"
        case contentFormatVersion = "ContentFormatVersion"
        case encryptedVaultKey = "EncryptedVaultKey"
    }
}
