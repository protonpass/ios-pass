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
import ProtonCore_Networking
import ProtonCore_Services

// https://protonmail.gitlab-pages.protontech.ch/Slim-API/pass/#tag/Share/operation/put_pass-v1-share-%7Benc_shareID%7D-user-%7Benc_userShareID%7D
public struct UpdateUserSharePermissionsEndpoint: Endpoint {
    public typealias Body = EmptyRequest
    public typealias Response = CodeOnlyResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod
    public var body: UserSharePermissionRequest?

    public init(shareId: String,
                userId: String,
                request: UserSharePermissionRequest) {
        debugDescription = "Update a user's share persmission"
        path = "/pass/v1/share/\(shareId)/user/\(userId)"
        method = .put
        body = request
    }
}

public struct UserSharePermissionRequest {
    public let shareRoleID: String?
    public let expireTime: Int?

    enum CodingKeys: String, CodingKey {
        case shareRoleID = "ShareRoleID"
        case expireTime = "ExpireTime"
    }

    public init(shareRole: ShareRole?, expireTime: Int?) {
        shareRoleID = shareRole?.rawValue
        self.expireTime = expireTime
    }
}