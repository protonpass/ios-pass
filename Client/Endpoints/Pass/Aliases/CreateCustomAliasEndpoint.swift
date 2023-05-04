//
// CreateCustomAliasEndpoint.swift
// Proton Pass - Created on 15/09/2022.
// Copyright (c) 2022 Proton Technologies AG
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

import ProtonCore_Networking
import ProtonCore_Services

public struct CreateCustomAliasEndpoint: Endpoint {
    public typealias Body = CreateCustomAliasRequest
    public typealias Response = CreateItemResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod
    public var body: CreateCustomAliasRequest?

    public init(shareId: String, request: CreateCustomAliasRequest) {
        self.debugDescription = "Create a custom alias"
        self.path = "/pass/v1/share/\(shareId)/alias/custom"
        self.method = .post
        self.body = request
    }
}