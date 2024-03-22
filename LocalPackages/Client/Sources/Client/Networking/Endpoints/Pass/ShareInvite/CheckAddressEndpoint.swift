//
// CheckAddressEndpoint.swift
// Proton Pass - Created on 06/03/2024.
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
//

import ProtonCoreNetworking
import ProtonCoreServices

struct CheckAddressEndpoint: Endpoint {
    typealias Body = CheckAddressRequest
    typealias Response = CheckAddressResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: CheckAddressRequest?

    init(shareId: String, emails: [String]) {
        assert(emails.count <= 10, "At most 10 addresses are allowed")
        debugDescription = "Check if an address can be invited"
        path = "/pass/v1/share/\(shareId)/invite/check_address"
        method = .post
        body = .init(emails: emails)
    }
}

struct CheckAddressRequest: Sendable, Encodable {
    // periphery:ignore
    let emails: [String]

    enum CodingKeys: String, CodingKey {
        case emails = "Emails"
    }
}

struct CheckAddressResponse: Sendable, Decodable {
    // Optional array because otherwise decode process would fail
    // when receiving an empty array instead of null
    let emails: [String]?
}
