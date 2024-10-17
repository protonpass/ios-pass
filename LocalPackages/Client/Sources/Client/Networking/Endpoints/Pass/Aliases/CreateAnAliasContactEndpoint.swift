//
// CreateAnAliasContactEndpoint.swift
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

public struct CreateAContactRequest: Sendable, Encodable {
    public let email: String
    public let name: String?

    public init(email: String, name: String?) {
        self.email = email
        self.name = name
    }

    enum CodingKeys: String, CodingKey {
        case email = "Email"
        case name = "Name"
    }
}

public struct CreateAContactResponse: Decodable, Sendable {
    public let contact: AliasContact
}

struct CreateAContactEndpoint: Endpoint {
    typealias Body = CreateAContactRequest
    typealias Response = CreateALightContactResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: CreateAContactRequest?

    init(shareId: String, itemId: String, request: CreateAContactRequest) {
        debugDescription = "Create an alias contact"
        path = "/pass/v1/share/\(shareId)/alias/\(itemId)/contact"
        method = .post
        body = request
    }
}
