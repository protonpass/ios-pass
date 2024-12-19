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

struct GetLogoEndpoint: Endpoint, @unchecked Sendable {
    typealias Body = EmptyRequest
    typealias Response = EmptyResponse

    var debugDescription: String
    var path: String
    var parameters: [String: Any]?

    init(domain: String, size: Int = 32, mode: String = "dark", format: String = "png") {
        debugDescription = "Get fav icon of a domain"
        path = "/core/v4/images/logo"
        let host = URL(string: domain)?.host ?? domain
        parameters = ["Domain": host, "Size": size, "Mode": mode, "Format": format]
    }
}
