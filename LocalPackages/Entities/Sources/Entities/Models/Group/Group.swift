//
// Group.swift
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

public enum GroupPermissions: Int, Decodable, Sendable {
    case nobodyCanSend = 0
    case groupMembersCanSend = 1
    case orgMembersCanSend = 2
    case everyoneCanSend = 3
}

public struct GroupInfo: Sendable, Equatable, Hashable {
    public let group: Group
    public let members: [GroupMember]

    public init(group: Group, members: [GroupMember]) {
        self.group = group
        self.members = members
    }

    public var memberCounts: Int {
        members.count
    }
}

public struct Group: Decodable, Sendable, Equatable, Hashable, Identifiable {
    private let ID: String
    public let permissions: GroupPermissions
    public let name: String
    public let address: GroupAddress?
    public let createTime: Int
    public let flags: Int
    public let description: String?

    public var id: String {
        // swiftformat:disable:next redundantSelf
        self.ID
    }

    public init(ID: String,
                permissions: GroupPermissions,
                name: String,
                address: GroupAddress?,
                createTime: Int,
                flags: Int,
                description: String?) {
        self.ID = ID
        self.permissions = permissions
        self.name = name
        self.address = address
        self.createTime = createTime
        self.flags = flags
        self.description = description
    }
}

//
// public struct GroupAddress: Decodable, Sendable, Equatable, Hashable {
//    public let email: String
// }

// struct NetworkResponse: Codable {
//    let code: Int
//    let groups: [Group]
//    let total: Int
//
//    enum CodingKeys: String, CodingKey {
//        case code = "Code"
//        case groups = "Groups"
//        case total = "Total"
//    }
// }

// struct Group: Codable {
//    let id: String
//    let name: String
//    let address: Address
//    let permissions: Int
//    let createTime: Int
//    let flags: Int
//    let groupVisibility: Int
//    let memberVisibility: Int
//    let description: String
//
//    enum CodingKeys: String, CodingKey {
//        case id = "ID"
//        case name = "Name"
//        case address = "Address"
//        case permissions = "Permissions"
//        case createTime = "CreateTime"
//        case flags = "Flags"
//        case groupVisibility = "GroupVisibility"
//        case memberVisibility = "MemberVisibility"
//        case description = "Description"
//    }
// }
// ']

public struct GroupAddress: Codable, Sendable, Equatable, Hashable {
    let ID: String
    public let domainID: String
    public let email: String
    public let status: Int
    public let type: Int
    public let receive: Int
    public let send: Int
    public let displayName: String
    public let signature: String
    public let order: Int
    public let priority: Int
    public let catchAll: Bool
    public let protonMX: Bool
    public let confirmationState: Int
    public let hasKeys: Int
    public let keys: [GroupAddressKey]
    public let signedKeyList: SignedKeyList?
}

public struct GroupAddressKey: Codable, Sendable, Equatable, Hashable {
    let ID: String
    public let primary: Int
    public let flags: Int
    public let fingerprint: String
    public let fingerprints: [String]
    public let privateKey: String
    public let token: String
    public let signature: String
    public let active: Int
}

public struct SignedKeyList: Codable, Sendable, Equatable, Hashable {
    public let minEpochID: Int?
    public let maxEpochID: Int?
    public let expectedMinEpochID: Int
    public let data: String
    public let obsolescenceToken: String?
    public let revision: Int
    public let signature: String
}
