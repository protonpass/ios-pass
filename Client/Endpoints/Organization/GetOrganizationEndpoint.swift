//
// GetOrganizationEndpoint.swift
// Proton Pass - Created on 03/04/2023.
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

import ProtonCore_Networking
import ProtonCore_Services

/// This should be supported by core but at the time of writting, `Organization` object from Core didn't
/// contain the `planName` properties that Pass is interested in.
/// So this endpoint is a workaround to get user's plan name
public struct OrganizationLite: Codable {
    public let planName: String?
}

public struct GetOrganizationResponse: Decodable {
    let code: Int
    let organization: OrganizationLite
}

public struct GetOrganizationEndpoint: Endpoint {
    public typealias Body = EmptyRequest
    public typealias Response = GetOrganizationResponse

    public var debugDescription: String
    public var path: String

    public init() {
        self.debugDescription = "Get organization"
        self.path = "/core/v4/organizations"
    }
}
