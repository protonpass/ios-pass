//
// UpdateUserSharePermissionsEndpoint.swift
// Proton Pass - Created on 11/07/2023.
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

import Entities
import ProtonCoreNetworking

struct UpdateUserSharePermissionsEndpoint: Endpoint {
    typealias Body = UserSharePermissionRequest
    typealias Response = CodeOnlyResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: UserSharePermissionRequest?

    init(shareId: String,
         userShareId: String,
         request: UserSharePermissionRequest) {
        debugDescription = "Update a user's share persmission"
        path = "/pass/v1/share/\(shareId)/user/\(userShareId)"
        method = .put
        body = request
    }
}

public struct UserSharePermissionRequest: Encodable, Sendable {
    let shareRoleID: String?
    let expireTime: Int?

    enum CodingKeys: String, CodingKey {
        case shareRoleID = "ShareRoleID"
        case expireTime = "ExpireTime"
    }

    public init(shareRole: ShareRole?, expireTime: Int?) {
        shareRoleID = shareRole?.rawValue
        self.expireTime = expireTime
    }
}
