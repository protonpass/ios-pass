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

public struct Share: Decodable, Hashable, Equatable, Sendable, Identifiable /* , ShareElementProtocol */ {
    /// ID of the share
    public let shareID: String

    /// ID of the vault this share belongs to
    public let vaultID: String

    /// User address ID that has access to this share
    public let addressID: String

    /// Type of share
    public let targetType: Int

    /// ID of the top shared objec. This can be the id of a vault or an Item
    public let targetID: String

    /// Permissions for this share
    public let permission: Int

    /// Role given to the user when invited with sharing feature
    public let shareRoleID: String

    /// Number of people actually linked to this share through sharing. If 0 the vault is not shared
    public let members: Int

    /// Max members allowed for the target of this share
    public let maxMembers: Int

    /// How many invites are pending of acceptance
    public let pendingInvites: Int

    /// How many new user invites are waiting for an admin to create the proper invite
    public let newUserInvitesReady: Int

    /// Whether the user is owner of this vault
    public let owner: Bool

    /// Whether this share is shared or not this **only represents sharing if share is linked to Vaults** to know
    /// if item is shared we need to base ourselves on `shareCount` in `Item` model.
    public let shared: Bool

    /// Base64 encoded encrypted content of the Vault. Can be null for item shares
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

    public var shareRole: ShareRole {
        .init(rawValue: shareRoleID) ?? .read
    }

    public var id: String { shareID }

    public var shareId: String {
        shareID
    }

    public var addressId: String {
        addressID
    }

    public var isOwner: Bool {
        owner
    }

    /// Decoded vault content
    public var vaultContent: VaultContent?

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
        self.targetType = Int(targetType)
        self.targetID = targetID
        self.permission = Int(permission)
        self.shareRoleID = shareRoleID
        members = Int(targetMembers)
        maxMembers = Int(targetMaxMembers)
        self.pendingInvites = Int(pendingInvites)
        self.newUserInvitesReady = Int(newUserInvitesReady)
        self.owner = owner
        self.shared = shared
        self.content = content
        self.contentKeyRotation = contentKeyRotation
        self.contentFormatVersion = contentFormatVersion
        self.expireTime = expireTime
        self.createTime = createTime
        self.canAutoFill = canAutoFill
    }

    /// Custom Decodable implementation
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        shareID = try container.decode(String.self, forKey: .shareID)
        vaultID = try container.decode(String.self, forKey: .vaultID)
        addressID = try container.decode(String.self, forKey: .addressID)
        targetType = try container.decode(Int.self, forKey: .targetType)
        targetID = try container.decode(String.self, forKey: .targetID)
        permission = try container.decode(Int.self, forKey: .permission)
        shareRoleID = try container.decode(String.self, forKey: .shareRoleID)
        members = try container.decode(Int.self, forKey: .targetMembers)
        maxMembers = try container.decode(Int.self, forKey: .targetMaxMembers)
        pendingInvites = try container.decode(Int.self, forKey: .pendingInvites)
        newUserInvitesReady = try container.decode(Int.self, forKey: .newUserInvitesReady)
        owner = try container.decode(Bool.self, forKey: .owner)
        shared = try container.decode(Bool.self, forKey: .shared)
        content = try container.decodeIfPresent(String.self, forKey: .content)
        contentKeyRotation = try container.decodeIfPresent(Int64.self, forKey: .contentKeyRotation)
        contentFormatVersion = try container.decodeIfPresent(Int64.self, forKey: .contentFormatVersion)
        expireTime = try container.decodeIfPresent(Int64.self, forKey: .expireTime)
        createTime = try container.decode(Int64.self, forKey: .createTime)
        canAutoFill = try container.decode(Bool.self, forKey: .canAutoFill)
    }

    private enum CodingKeys: String, CodingKey {
        case shareID, vaultID, addressID, targetType, targetID, permission, shareRoleID, targetMembers,
             targetMaxMembers
        case pendingInvites, newUserInvitesReady, owner, shared, content, contentKeyRotation, contentFormatVersion
        case expireTime, createTime, canAutoFill
    }

    public func update(with vaultContent: VaultContent?) -> Share {
        var updated = self
        updated.vaultContent = vaultContent
        return updated
    }
}

// MARK: - Computed properties

public extension Share {
    var isVaultRepresentation: Bool {
        shareType == .vault
    }

    var isAdmin: Bool {
        shareRole == ShareRole.admin
    }

    var canEdit: Bool {
        shareRole != ShareRole.read
    }

    var totalOverallMembers: Int {
        members + pendingInvites
    }

    var reachedSharingLimit: Bool {
        maxMembers <= totalOverallMembers
    }

    var canShareWithMorePeople: Bool {
        (isOwner || isAdmin) && !reachedSharingLimit
    }

    var name: String? {
        vaultContent?.name
    }
}

public extension [Share] {
    var representingVaults: [Share] {
        self.filter(\.isVaultRepresentation)
    }
}
