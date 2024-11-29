//
// ShareElement.swift
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

import Foundation

// Protocol to define shared properties and behaviors
public protocol ShareElementProtocol: Identifiable, Hashable, Equatable, Sendable {
    var id: String { get }
    var shareId: String { get }
    var addressId: String { get }
    var isOwner: Bool { get }
    var shareRole: ShareRole { get }
    var members: Int { get }
    var maxMembers: Int { get }
    var pendingInvites: Int { get }
    var newUserInvitesReady: Int { get }
    var shared: Bool { get }
    var createTime: Int64 { get }
    var canAutoFill: Bool { get }
}

public extension ShareElementProtocol {
    var isVault: Bool {
        self is Vault
    }

    var vault: Vault? {
        self as? Vault
    }

    var isAdmin: Bool {
        shareRole == ShareRole.admin
    }

    var canEdit: Bool {
        shareRole != ShareRole.read
    }

    var canShare: Bool {
        isOwner || isAdmin
    }
}
