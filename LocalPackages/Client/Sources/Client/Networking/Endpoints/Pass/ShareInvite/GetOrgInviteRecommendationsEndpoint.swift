//
// GetOrgInviteRecommendationsEndpoint.swift
// Proton Pass - Created on 06/11/2025.
// Copyright (c) 2025 Proton Technologies AG
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

struct GetOrgInviteRecommendationsResponse: Sendable, Decodable {
    let recommendation: OrganizationRecommendations
}

struct GetOrgInviteRecommendationsEndpoint: @unchecked Sendable, Endpoint {
    typealias Body = EmptyRequest
    typealias Response = GetOrgInviteRecommendationsResponse

    var debugDescription: String
    var path: String
    var parameters: [String: Any]?

    init(shareId: String, query: InviteRecommendationsQuery) {
        debugDescription = "Get organization invite recommendations"
        path = "/pass/v1/share/\(shareId)/invite/recommended_emails/organization"
        var parameters: [String: Any] = [:]
        if let lastToken = query.lastToken {
            parameters["Since"] = lastToken
        }

        parameters["PageSize"] = query.pageSize

        if !query.email.isEmpty {
            parameters["StartsWith"] = query.email
        }
        self.parameters = parameters
    }
}
