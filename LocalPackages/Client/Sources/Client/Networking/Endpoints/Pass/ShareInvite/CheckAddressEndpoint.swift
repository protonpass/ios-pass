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

public struct CheckAddressEndpoint: Endpoint {
    public typealias Body = CheckAddressRequest
    public typealias Response = CheckAddressResponse

    public var debugDescription: String
    public var path: String
    public var method: HTTPMethod
    public var body: CheckAddressRequest?

    public init(shareId: String, emails: [String]) {
        assert(emails.count <= 10, "At most 10 addresses are allowed")
        debugDescription = "Check if an address can be invited"
        path = "/pass/v1/share/\(shareId)/invite/check_address"
        method = .post
        body = .init(emails: emails)
    }
}

public struct CheckAddressRequest: Sendable, Codable {
    public let emails: [String]

    enum CodingKeys: String, CodingKey {
        case emails = "Emails"
    }
}

public typealias CheckAddressResponse = CheckAddressRequest
