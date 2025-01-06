//
// UpdateContactEndpoint.swift
// Proton Pass - Created on 02/10/2024.
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

public struct UpdateContactRequest: Sendable, Encodable {
    public let blocked: Bool

    public init(blocked: Bool) {
        self.blocked = blocked
    }

    enum CodingKeys: String, CodingKey {
        case blocked = "Blocked"
    }
}

struct CreateALiteContactResponse: Decodable, Sendable {
    let contact: AliasContactLite
}

struct UpdateContactEndpoint: Endpoint {
    typealias Body = UpdateContactRequest
    typealias Response = CreateALiteContactResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: UpdateContactRequest?

    init(shareId: String, itemId: String, contactId: String, request: UpdateContactRequest) {
        debugDescription = "Update an alias contact"
        path = "/pass/v1/share/\(shareId)/alias/\(itemId)/contact/\(contactId)/blocked"
        method = .put
        body = request
    }
}
