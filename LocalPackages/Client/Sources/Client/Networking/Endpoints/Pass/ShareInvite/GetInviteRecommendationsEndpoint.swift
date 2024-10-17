//
// GetInviteRecommendationsEndpoint.swift
// Proton Pass - Created on 14/12/2023.
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
//

import Entities
import ProtonCoreNetworking

struct GetInviteRecommendationsResponse: Sendable, Decodable {
    let recommendation: InviteRecommendations
}

struct GetInviteRecommendationsEndpoint: @unchecked Sendable, Endpoint {
    typealias Body = EmptyRequest
    typealias Response = GetInviteRecommendationsResponse

    var debugDescription: String
    var path: String
    var parameters: [String: Any]?

    init(shareId: String, query: InviteRecommendationsQuery) {
        debugDescription = "Get invite recommendations"
        path = "/pass/v1/share/\(shareId)/invite/recommended_emails"
        var parameters: [String: Any] = [:]
        if let lastToken = query.lastToken {
            parameters["PlanSince"] = lastToken
        }

        parameters["PlanPageSize"] = query.pageSize

        if !query.email.isEmpty {
            parameters["StartsWith"] = query.email
        }
        self.parameters = parameters
    }
}
