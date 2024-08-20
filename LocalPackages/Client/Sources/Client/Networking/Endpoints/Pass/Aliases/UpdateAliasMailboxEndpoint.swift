//
// UpdateAliasMailboxEndpoint.swift
// Proton Pass - Created on 06/08/2024.
// Copyright (c) 2024 Proton Technologies AG
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

public struct UpdateAliasMailboxRequest: Sendable, Encodable {
    let defaultMailboxID: String

    public init(defaultMailboxID: String) {
        self.defaultMailboxID = defaultMailboxID
    }

    enum CodingKeys: String, CodingKey {
        case defaultMailboxID = "DefaultMailboxID"
    }
}

struct UpdateAliasMailboxEndpoint: Endpoint {
    typealias Body = UpdateAliasMailboxRequest
    typealias Response = GetAliasSettingsResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: UpdateAliasMailboxRequest?

    init(request: UpdateAliasMailboxRequest) {
        debugDescription = "Update user alias default mailbox"
        path = "/pass/v1/user/alias/settings/default_mailbox_id"
        method = .put
        body = request
    }
}
