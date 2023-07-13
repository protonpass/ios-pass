//
//  UserShareInfos.swift
//
//
//  Created by martin on 13/07/2023.
//

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
