//
// Vault.swift
// Proton Pass - Created on 18/07/2022.
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

// public struct Vault: ShareElementProtocol {
//    public let id: String
//    public let shareId: String
//    public let addressId: String
//    public let name: String
//    public let description: String
//    public let displayPreferences: ProtonPassVaultV1_VaultDisplayPreferences
//    public let isOwner: Bool
//    /// Role given to the user when invited with sharing feature
//    public let shareRole: ShareRole
//
//    /// Number of people actually linked to this share through sharing. If 0 the vault is not shared
//    public let members: Int
//
//    /// Max members allowed for the target of this vault
//    public let maxMembers: Int
//
//    /// How many invites are pending of acceptance
//    public let pendingInvites: Int
//
//    /// How many new user invites are waiting for an admin to create the proper invite
//    public let newUserInvitesReady: Int
//
//    /// Whether this share is shared or not
//    public let shared: Bool
//
//    /// Time of creation of this vault
//    public let createTime: Int64
//
//    public let canAutoFill: Bool
//
//    public init(id: String,
//                shareId: String,
//                addressId: String,
//                name: String,
//                description: String,
//                displayPreferences: ProtonPassVaultV1_VaultDisplayPreferences,
//                isOwner: Bool,
//                shareRole: ShareRole,
//                members: Int,
//                maxMembers: Int,
//                pendingInvites: Int,
//                newUserInvitesReady: Int,
//                shared: Bool,
//                createTime: Int64,
//                canAutoFill: Bool) {
//        self.id = id
//        self.shareId = shareId
//        self.name = name
//        self.description = description
//        self.displayPreferences = displayPreferences
//        self.addressId = addressId
//        self.isOwner = isOwner
//        self.shareRole = shareRole
//        self.members = members
//        self.maxMembers = maxMembers
//        self.pendingInvites = pendingInvites
//        self.newUserInvitesReady = newUserInvitesReady
//        self.shared = shared
//        self.createTime = createTime
//        self.canAutoFill = canAutoFill
//    }
// }
//
//// MARK: - Computed properties
//
// public extension Vault {
//    var totalOverallMembers: Int {
//        members + pendingInvites
//    }
//
//    var reachedSharingLimit: Bool {
//        maxMembers <= totalOverallMembers
//    }
//
//    var canShareVaultWithMorePeople: Bool {
//        isAdmin && !reachedSharingLimit
//    }
// }
