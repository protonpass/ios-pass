//
// InviteNewUserToShareEndpoint.swift
// Proton Pass - Created on 13/10/2023.
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

import Entities
import Foundation
import ProtonCoreNetworking
import ProtonCoreServices

public struct InviteNewUserToShareEndpoint: Endpoint {
    public typealias Body = InviteNewUserToShareRequest
    public typealias Response = CodeOnlyResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod
    public var body: InviteNewUserToShareRequest?

    public init(shareId: String, request: InviteNewUserToShareRequest) {
        debugDescription = "Invite non Proton user to share"
        path = "/pass/v1/share/\(shareId)/invite/new_user"
        method = .post
        body = request
    }
}

public struct InviteNewUserToShareRequest: Sendable {
    /// Email of the target user
    public let email: String
    /// Invite target type. 1 = Vault, 2 = Item
    public let targetType: Int
    /// Base64 signature of "inviteemail|base64(vaultKey)" signed with the admin's address key
    public let signature: String
    /// ShareRoleID for this invite. The values are in the top level Pass docs.
    public let shareRoleId: String
    /// Invite encrypted item ID (only in case the invite is of type Item)
    public let itemId: String?
    /// Expiration time for the share
    public let expirationTime: Int?

    public init(email: String,
                targetType: TargetType,
                signature: String,
                shareRole: ShareRole,
                itemId: String? = nil,
                expirationDate: Date? = nil) {
        self.email = email
        self.targetType = Int(targetType.rawValue)
        self.signature = signature
        shareRoleId = shareRole.rawValue
        self.itemId = itemId
        if let date = expirationDate?.timeIntervalSince1970 {
            expirationTime = Int(date)
        } else {
            expirationTime = nil
        }
    }
}

extension InviteNewUserToShareRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case email = "Email"
        case targetType = "TargetType"
        case signature = "Signature"
        case shareRoleId = "ShareRoleID"
        case itemId = "ItemID"
        case expirationTime = "ExpirationTime"
    }
}
