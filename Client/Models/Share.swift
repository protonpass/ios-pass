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
    public let shareID: String
    public let vaultID: String
    public let targetType: Int
    public let targetID: String
    public let permission: Int
    public let acceptanceSignature: String
    public let inviterEmail: String
    public let inviterAcceptanceSignature: String
    public let signingKey: String
    public let signingKeyPassphrase: String?
    public let content: String?
    public let contentRotationID: String
    public let contentEncryptedAddressSignature: String
    public let contentEncryptedVaultSignature: String
    public let contentSignerEmail: String
    public let contentFormatVersion: Int
    public let expireTime: Double?
    public let createTime: Double

    public init(shareID: String,
                vaultID: String,
                targetType: Int,
                targetID: String,
                permission: Int,
                acceptanceSignature: String,
                inviterEmail: String,
                inviterAcceptanceSignature: String,
                signingKey: String,
                signingKeyPassphrase: String?,
                content: String?,
                contentRotationID: String,
                contentEncryptedAddressSignature: String,
                contentEncryptedVaultSignature: String,
                contentSignerEmail: String,
                contentFormatVersion: Int,
                expireTime: Double?,
                createTime: Double) {
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
        self.contentSignerEmail = contentSignerEmail
        self.contentFormatVersion = contentFormatVersion
        self.expireTime = expireTime
        self.createTime = createTime
    }
}

public struct PartialShare: Codable {
    public let shareID: String
    public let vaultID: String
    public let targetType: Int
    public let targetID: String
    public let permission: Int
    public let acceptanceSignature: String
    public let inviterEmail: String
    public let inviterAcceptanceSignature: String
    public let expireTime: Double?
    public let createTime: Double

    public init(shareID: String,
                vaultID: String,
                targetType: Int,
                targetID: String,
                permission: Int,
                acceptanceSignature: String,
                inviterEmail: String,
                inviterAcceptanceSignature: String,
                expireTime: Double?,
                createTime: Double) {
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
