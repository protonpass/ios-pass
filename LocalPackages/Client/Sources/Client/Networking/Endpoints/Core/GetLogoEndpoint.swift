//
// GetLogoEndpoint.swift
// Proton Pass - Created on 13/04/2023.
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

import Foundation
import ProtonCoreNetworking
import ProtonCoreServices

// Dummy empty response
public struct GetLogoResponse: Decodable {}

public struct GetLogoEndpoint: Endpoint {
    public typealias Body = EmptyRequest
    public typealias Response = GetLogoResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod
    public var parameters: [String: Any]?

    public init(domain: String) {
        debugDescription = "Get fav icon of a domain"
        path = "/core/v4/images/logo"
        method = .get
        let host = URL(string: domain)?.host ?? domain
        parameters = ["Domain": host, "Size": 32, "Mode": "dark"]
    }
}
