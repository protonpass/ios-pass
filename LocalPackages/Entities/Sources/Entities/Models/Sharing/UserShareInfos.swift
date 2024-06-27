//
// UserShareInfos.swift
// Proton Pass - Created on 15/09/2022.
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

// MARK: - User share informations & permissions

public struct UserShareInfos: Codable, Hashable, Identifiable, Sendable {
    public let shareID: String
    public let userName: String
    public let userEmail: String
    public let owner: Bool
    public let targetType: Int
    public let targetID: String
    public let permission: Int
    public let shareRoleID: String
    public let expireTime: Int?
    public let createTime: Int?

    public var shareRole: ShareRole {
        .init(rawValue: shareRoleID) ?? .read
    }

    public var id: String {
        shareID
    }
}
