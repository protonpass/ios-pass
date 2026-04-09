//
// GroupMember.swift
// Proton Pass - Created on 30/07/2025.
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

public enum GroupMemberType: Int, Decodable, Sendable {
    case internalMember = 0
    case external = 1
    case internalTypeExternal = 2
}

public struct GroupMemberPermission: OptionSet, Sendable, Decodable {
    public let rawValue: Int

    // MARK: - Init

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    // MARK: - Options

    public static let none: Self = []
    public static let send = Self(rawValue: 1 << 0)
    public static let leave = Self(rawValue: 1 << 1)
    public static let owner = Self(rawValue: 1 << 2)
    public static let ownerWithKeys = Self(rawValue: 1 << 3)

    // MARK: - Derived Semantics

    /// True if the member is an owner (with or without keys)
    public var isOwner: Bool {
        contains(.owner)
    }

    /// True if the member is an owner AND has keys
    public var hasOwnerKeys: Bool {
        contains([.owner, .ownerWithKeys])
    }

    /// Validates the invariant:
    /// `.ownerWithKeys` cannot exist without `.owner`
    public var isValid: Bool {
        if contains(.ownerWithKeys), !contains(.owner) {
            return false
        }
        return true
    }
}

public enum GroupMemberState: Int, Decodable, Sendable {
    case pending = 0
    case active = 1
    case outdated = 2
    case paused = 3
    case rejected = 4
}

public struct GroupMember: Decodable, Sendable, Equatable, Hashable, Identifiable {
    private let ID: String
    public let createTime: Int
    public let groupID: String
    public let state: GroupMemberState
    public let type: GroupMemberType
    public let addressID: String?
    public let email: String?
    public let permissions: Int

    public var id: String {
        // swiftformat:disable:next redundantSelf
        self.ID
    }

    public var groupPermissions: GroupMemberPermission {
        GroupMemberPermission(rawValue: permissions)
    }

    public init(ID: String,
                createTime: Int,
                groupID: String,
                state: GroupMemberState,
                type: GroupMemberType,
                addressID: String?,
                email: String?,
                permissions: Int) {
        self.ID = ID
        self.createTime = createTime
        self.groupID = groupID
        self.state = state
        self.type = type
        self.addressID = addressID
        self.email = email
        self.permissions = permissions
    }
}
