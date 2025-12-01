//
// InviteeData+Extensions.swift
// Proton Pass - Created on 16/09/2025.
// Copyright (c) 2025 Proton Technologies AG
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

import Entities

extension [InviteeData] {
    func existingUserInvitesRequests(targetType: TargetType, itemId: String?) -> [InviteUserToShareRequest] {
        compactMap {
            if case let .existing(email, keys, role) = $0 {
                return InviteUserToShareRequest(keys: keys,
                                                email: email,
                                                targetType: targetType,
                                                shareRole: role,
                                                itemId: itemId)
            }
            return nil
        }
    }

    func newUserInvitesRequests(targetType: TargetType, itemId: String?) -> [InviteNewUserToShareRequest] {
        compactMap {
            if case let .new(email, signature, role) = $0 {
                return InviteNewUserToShareRequest(email: email,
                                                   targetType: targetType,
                                                   signature: signature,
                                                   shareRole: role,
                                                   itemId: itemId)
            }
            return nil
        }
    }
}
