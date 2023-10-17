//
// ShareInvitee.swift
// Proton Pass - Created on 18/10/2023.
// Copyright (c) 2023 Proton Technologies AG
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
//

import Foundation

public protocol ShareInvitee: Identifiable {
    var id: String { get }
    var email: String { get }
    var subtitle: String { get }
    var isPending: Bool { get }
    var isAdmin: Bool { get }
    var showConfirmAccessButton: Bool { get }
    var options: [ShareEntryOption] { get }
}

public enum ShareEntryOption: Identifiable {
    case resendInvitation(inviteId: String)
    case cancelInvitation(inviteId: String)
    case updateRole(shareId: String, role: ShareRole)
    case revokeAccess(shareId: String)
    case transferOwnership(NewOwner)

    public var id: String {
        switch self {
        case let .resendInvitation(id):
            "resendInvitation" + id
        case let .cancelInvitation(id):
            "cancelInvitation" + id
        case let .updateRole(id, _):
            "updateRole" + id
        case let .revokeAccess(id):
            "revokeAccess" + id
        case let .transferOwnership(owner):
            "transferOwnership" + owner.shareId
        }
    }
}

public struct NewOwner: Identifiable {
    public let email: String
    public let shareId: String

    public var id: String {
        shareId
    }

    public init(email: String, shareId: String) {
        self.email = email
        self.shareId = shareId
    }
}
