//
// PromoteNewUserInviteEndpoint.swift
// Proton Pass - Created on 18/10/2023.
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
import ProtonCoreNetworking
import ProtonCoreServices

public struct PromoteNewUserInviteEndpoint: Endpoint {
    public typealias Body = PromoteNewUserInviteRequest
    public typealias Response = CodeOnlyResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod
    public var body: PromoteNewUserInviteRequest?

    public init(shareId: String, inviteId: String, keys: [ItemKey]) {
        debugDescription = "Confirm new user invite"
        path = "/pass/v1/share/\(shareId)/invite/new_user/\(inviteId)/keys"
        method = .post
        body = .init(keys: keys)
    }
}

public struct PromoteNewUserInviteRequest: Encodable, Sendable {
    let keys: [ItemKey]

    enum CodingKeys: String, CodingKey {
        case keys = "Keys"
    }
}
