//
// AcceptInviteEndpoint.swift
// Proton Pass - Created on 13/07/2023.
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

struct AcceptInviteEndpoint: Endpoint {
    typealias Body = AcceptInviteRequest
    typealias Response = GetShareResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: AcceptInviteRequest?

    init(with inviteToken: String, and request: AcceptInviteRequest) {
        debugDescription = "Accept an invite"
        path = "/pass/v1/invite/\(inviteToken)"
        method = .post
        body = request
    }
}

public struct AcceptInviteRequest: Sendable {
    /// Invite keys encrypted and signed with the User Key
    public let keys: [ItemKey]

    public init(keys: [ItemKey]) {
        self.keys = keys
    }
}

extension AcceptInviteRequest: Encodable {
    enum CodingKeys: String, CodingKey {
        case keys = "Keys"
    }
}
