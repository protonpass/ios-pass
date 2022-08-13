//
// GetShareResponse.swift
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

import Foundation

struct ShareResponse: Decodable {
    /// ID of the share
    let shareID: String

    /// ID of the vault this share belongs to
    let vaultID: String

    /// Type of share. 1 for vault, 2 for label and 3 for item
    let targetType: Int16

    /// ID of the top shared object
    let targetID: String

    /// Permissions for this share
    let permission: Int16

    /// Base64 encoded signature of the vault signing key fingerprint
    let acceptanceSignature: String

    /// Email that invited you to the share
    let inviterEmail: String

    /// Base64 encoded signature of the vault signing key fingerprint by your inviter
    let inviterAcceptanceSignature: String

    /// Armored signing key for the share.
    /// It will be a private key if the user is a share admin
    let signingKey: String

    /// Base64 encoded encrypted passphrase to open the signing key. Only for admins.
    let signingKeyPassphrase: String?

    /// Base64 encoded encrypted content of the share. Can be null for item shares
    let content: String?

    /// ID for the key needed to decrypt the share.
    /// For vault shares the vault key will be used, for label shares the label keys will
    let contentRotationID: String

    /// Base64 encoded encrypted signature of the share content done by
    /// the signer email address key, and encrypted with the vault key
    let contentEncryptedAddressSignature: String

    /// Base64 encoded encrypted signature of the share content signed and encrypted by the vault key
    let contentEncryptedVaultSignature: String

    /// Email address of the content's signer
    let contentSignatureEmail: String

    /// Version of the content's format
    let contentFormatVersion: Int16

    /// Expiration time for this share
    let expireTime: Int64?

    /// Time of creation of this share
    let createTime: Int64
}
