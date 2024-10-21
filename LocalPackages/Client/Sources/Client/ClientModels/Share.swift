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

import CryptoKit
import Entities
import Macro
import ProtonCoreCrypto
import ProtonCoreLogin

@Copyable
public struct Share: Decodable, Swift.Hashable, Equatable, Sendable {
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
}

extension Share: Identifiable {
    public var id: String { shareID }
}
