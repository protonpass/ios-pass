//
// ShareItem.swift
// Proton Pass - Created on 19/11/2024.
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

public struct ShareItem: ShareElementProtocol {
    public let itemUuid: String
    public let vaultID: String
    public let shareId: String
    public let addressId: String
    public let name: String
    public let isOwner: Bool
    /// Role given to the user when invited with sharing feature
    public let shareRole: ShareRole
    /// Number of people actually linked to this share through sharing. If 0 the vault is not shared
    public let members: Int
    /// Max members allowed for the target of this vault
    public let maxMembers: Int
    /// How many invites are pending of acceptance
    public let pendingInvites: Int
    /// How many new user invites are waiting for an admin to create the proper invite
    public let newUserInvitesReady: Int
    /// Whether this share is shared or not
    public let shared: Bool
    /// Time of creation of this vault
    public let createTime: Int64
    public let canAutoFill: Bool
    public let note: String
    public let contentData: ItemContentData

    public init(itemUuid: String,
                vaultID: String,
                shareId: String,
                addressId: String,
                name: String,
                isOwner: Bool,
                shareRole: ShareRole,
                members: Int,
                maxMembers: Int,
                pendingInvites: Int,
                newUserInvitesReady: Int,
                shared: Bool,
                createTime: Int64,
                canAutoFill: Bool,
                note: String,
                contentData: ItemContentData) {
        self.note = note
        self.contentData = contentData
        self.itemUuid = itemUuid
        self.vaultID = vaultID
        self.shareId = shareId
        self.addressId = addressId
        self.name = name
        self.isOwner = isOwner
        self.shareRole = shareRole
        self.members = members
        self.maxMembers = maxMembers
        self.pendingInvites = pendingInvites
        self.newUserInvitesReady = newUserInvitesReady
        self.shared = shared
        self.createTime = createTime
        self.canAutoFill = canAutoFill
    }

    public var id: String {
        "\(itemUuid)" + "\(shareId)"
    }
}

public extension ShareElementProtocol {
    var type: TargetType {
        switch self {
        case is Vault:
            .vault
        case is ShareItem:
            .item
        default:
            .unknown
        }
    }
}
