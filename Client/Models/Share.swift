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

import Foundation

public struct Share: Codable {
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

    public init(shareID: String,
                vaultID: String,
                targetType: Int16,
                targetID: String,
                permission: Int16,
                acceptanceSignature: String,
                inviterEmail: String,
                inviterAcceptanceSignature: String,
                signingKey: String,
                signingKeyPassphrase: String?,
                content: String?,
                contentRotationID: String,
                contentEncryptedAddressSignature: String,
                contentEncryptedVaultSignature: String,
                contentSignatureEmail: String,
                contentFormatVersion: Int16,
                expireTime: Int64?,
                createTime: Int64) {
        self.shareID = shareID
        self.vaultID = vaultID
        self.targetType = targetType
        self.targetID = targetID
        self.permission = permission
        self.acceptanceSignature = acceptanceSignature
        self.inviterEmail = inviterEmail
        self.inviterAcceptanceSignature = inviterAcceptanceSignature
        self.signingKey = signingKey
        self.signingKeyPassphrase = signingKeyPassphrase
        self.content = content
        self.contentRotationID = contentRotationID
        self.contentEncryptedAddressSignature = contentEncryptedAddressSignature
        self.contentEncryptedVaultSignature = contentEncryptedVaultSignature
        self.contentSignatureEmail = contentSignatureEmail
        self.contentFormatVersion = contentFormatVersion
        self.expireTime = expireTime
        self.createTime = createTime
    }
}

public struct PartialShare: Codable {
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

    public init(shareID: String,
                vaultID: String,
                targetType: Int16,
                targetID: String,
                permission: Int16,
                acceptanceSignature: String,
                inviterEmail: String,
                inviterAcceptanceSignature: String,
                expireTime: Int64?,
                createTime: Int64) {
        self.shareID = shareID
        self.vaultID = vaultID
        self.targetType = targetType
        self.targetID = targetID
        self.permission = permission
        self.acceptanceSignature = acceptanceSignature
        self.inviterEmail = inviterEmail
        self.inviterAcceptanceSignature = inviterAcceptanceSignature
        self.expireTime = expireTime
        self.createTime = createTime
    }
}
