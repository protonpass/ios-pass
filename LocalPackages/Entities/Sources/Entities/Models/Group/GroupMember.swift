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

public enum GroupMemberPermission: Int, Decodable, Sendable {
    case none = 0
    case send = 1
    case leave = 2
    case sendAndLeave = 3
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
    public let permissions: GroupMemberPermission

    public var id: String {
        // swiftformat:disable:next redundantSelf
        self.ID
    }

    public init(ID: String,
                createTime: Int,
                groupID: String,
                state: GroupMemberState,
                type: GroupMemberType,
                addressID: String?,
                email: String?,
                permissions: GroupMemberPermission) {
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
