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

public struct UserShareInfos: Codable {
    public let shareID, userName, userEmail, targetType: String
    public let targetID, permission, expireTime, createTime: String

    public init(shareID: String,
                userName: String,
                userEmail: String,
                targetType: String,
                targetID: String,
                permission: String,
                expireTime: String,
                createTime: String) {
        self.shareID = shareID
        self.userName = userName
        self.userEmail = userEmail
        self.targetType = targetType
        self.targetID = targetID
        self.permission = permission
        self.expireTime = expireTime
        self.createTime = createTime
    }

    enum CodingKeys: String, CodingKey {
        case shareID = "ShareID"
        case userName = "UserName"
        case userEmail = "UserEmail"
        case targetType = "TargetType"
        case targetID = "TargetID"
        case permission = "Permission"
        case expireTime = "ExpireTime"
        case createTime = "CreateTime"
    }
}
