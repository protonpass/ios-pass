//
// Share.swift
// Proton Pass - Created on 28/11/2024.
// Copyright (c) 2024 Proton Technologies AG
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

public struct Share: Decodable, Hashable, Equatable, Sendable, Identifiable {
    /// ID of the share
    public let shareID: String

    /// ID of the vault this share belongs to
    public let vaultID: String

    /// User address ID that has access to this share
    public let addressID: String

    /// Type of share
    public let targetType: Int64

    /// ID of the top shared object
    public let targetID: String

    /// Permissions for this share
    public let permission: Int64

    /// Role given to the user when invited with sharing feature
    public let shareRoleID: String

    /// Number of people actually linked to this share through sharing. If 0 the vault is not shared
    public let targetMembers: Int64

    /// Max members allowed for the target of this share
    public let targetMaxMembers: Int64

    /// How many invites are pending of acceptance
    public let pendingInvites: Int64

    /// How many new user invites are waiting for an admin to create the proper invite
    public let newUserInvitesReady: Int64

    /// Whether the user is owner of this vault
    public let owner: Bool

    /// Whether this share is shared or not
    public let shared: Bool

    /// Base64 encoded encrypted content of the share. Can be null for item shares
    public let content: String?

    public let contentKeyRotation: Int64?

    /// Version of the content's format
    public let contentFormatVersion: Int64?

    /// Expiration time for this share
    public let expireTime: Int64?

    /// Time of creation of this share
    public let createTime: Int64

    public let canAutoFill: Bool

    /// Enum representation of `targetType`
    public var shareType: TargetType {
        .init(rawValue: targetType) ?? .unknown
    }

    public var id: String { shareID }

    public init(shareID: String,
                vaultID: String,
                addressID: String,
                targetType: Int64,
                targetID: String,
                permission: Int64,
                shareRoleID: String,
                targetMembers: Int64,
                targetMaxMembers: Int64,
                pendingInvites: Int64,
                newUserInvitesReady: Int64,
                owner: Bool,
                shared: Bool,
                content: String?,
                contentKeyRotation: Int64?,
                contentFormatVersion: Int64?,
                expireTime: Int64?,
                createTime: Int64,
                canAutoFill: Bool) {
        self.shareID = shareID
        self.vaultID = vaultID
        self.addressID = addressID
        self.targetType = targetType
        self.targetID = targetID
        self.permission = permission
        self.shareRoleID = shareRoleID
        self.targetMembers = targetMembers
        self.targetMaxMembers = targetMaxMembers
        self.pendingInvites = pendingInvites
        self.newUserInvitesReady = newUserInvitesReady
        self.owner = owner
        self.shared = shared
        self.content = content
        self.contentKeyRotation = contentKeyRotation
        self.contentFormatVersion = contentFormatVersion
        self.expireTime = expireTime
        self.createTime = createTime
        self.canAutoFill = canAutoFill
    }
}
