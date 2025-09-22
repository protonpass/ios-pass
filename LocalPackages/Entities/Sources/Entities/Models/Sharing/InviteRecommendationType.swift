//
// InviteRecommendationType.swift
// Proton Pass - Created on 22/09/2025.
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

import Foundation

public enum InviteRecommendationType: Sendable, Equatable, Hashable, Identifiable {
    case email(String)
    case group(GroupInfo)

    public var id: Self { self }

    public var currentEmail: String? {
        switch self {
        case let .email(email):
            email
        case let .group(groupInfo):
            groupInfo.group.address?.email
        }
    }

    public var name: String {
        switch self {
        case let .email(email):
            email
        case let .group(groupInfo):
            groupInfo.group.name
        }
    }

    public var numberOfMembers: Int? {
        switch self {
        case let .group(groupInfo):
            groupInfo.members.count
        default:
            nil
        }
    }

    public var isEmail: Bool {
        switch self {
        case .email:
            true
        case .group:
            false
        }
    }
}
