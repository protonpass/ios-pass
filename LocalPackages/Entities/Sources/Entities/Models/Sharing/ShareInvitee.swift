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

public protocol ShareInvitee: Identifiable, Equatable {
    var id: String { get }
    var email: String { get }
    var subtitle: String { get }
    var isPending: Bool { get }
    var isAdmin: Bool { get }
    var shareRole: ShareRole { get }
    var shareType: TargetType { get }
    var options: [ShareInviteeOption] { get }
}

public enum ShareInviteeOption: Identifiable, Sendable {
    case remindExistingUserInvitation(inviteId: String)
    case cancelExistingUserInvitation(inviteId: String)
    case cancelNewUserInvitation(inviteId: String)
    case confirmAccess(PendingAccess)
    case updateRole(shareId: String, role: ShareRole)
    case revokeAccess(shareId: String)
    /// Display an alert to ask for confirmation before transferring
    case confirmTransferOwnership(NewOwner)
    /// Do the transfer
    case transferOwnership(NewOwner)

    public var id: String {
        UUID().uuidString
    }

    /// To show "Confirm access" button or not
    public var pendingAccess: PendingAccess? {
        if case let .confirmAccess(access) = self {
            access
        } else {
            nil
        }
    }
}

public struct NewOwner: Sendable, Identifiable {
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

/// Invitation to be confirmed (promoted)
public struct PendingAccess: Sendable {
    public let inviteId: String
    public let email: String

    public init(inviteId: String, email: String) {
        self.inviteId = inviteId
        self.email = email
    }
}
