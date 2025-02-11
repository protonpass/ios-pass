//
// CreateAliasAndAnotherItemEndpoint.swift
// Proton Pass - Created on 20/04/2023.
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

public struct CreateAliasAndAnotherItemResponse: Decodable, Sendable {
    public let bundle: Bundle

    public struct Bundle: Decodable, Sendable {
        let alias: Item
        let item: Item
    }
}

struct CreateAliasAndAnotherItemEndpoint: Endpoint {
    typealias Body = CreateAliasAndAnotherItemRequest
    typealias Response = CreateAliasAndAnotherItemResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: CreateAliasAndAnotherItemRequest?

    init(shareId: String, request: CreateAliasAndAnotherItemRequest) {
        debugDescription = "Create alias and another item"
        path = "/pass/v1/share/\(shareId)/item/with_alias"
        method = .post
        body = request
    }
}
