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
import ProtonCoreServices

public struct CreateAliasAndAnotherItemResponse: Decodable {
    let code: Int
    let bundle: Bundle

    public struct Bundle: Decodable {
        let alias: ItemRevision
        let item: ItemRevision
    }
}

public struct CreateAliasAndAnotherItemEndpoint: Endpoint {
    public typealias Body = CreateAliasAndAnotherItemRequest
    public typealias Response = CreateAliasAndAnotherItemResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod
    public var body: CreateAliasAndAnotherItemRequest?

    public init(shareId: String, request: CreateAliasAndAnotherItemRequest) {
        debugDescription = "Create alias and another item"
        path = "/pass/v1/share/\(shareId)/item/with_alias"
        method = .post
        body = request
    }
}
