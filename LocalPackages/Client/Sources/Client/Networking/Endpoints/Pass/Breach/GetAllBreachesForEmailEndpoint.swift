//
// GetAllBreachesForEmailEndpoint.swift
// Proton Pass - Created on 10/04/2024.
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

import Entities
import ProtonCoreNetworking

struct BreachesForCustomEmailResponse: Decodable, Equatable, Sendable {
    let breaches: EmailBreaches
}

struct GetBreachesForCustomEmailEndpoint: Endpoint {
    typealias Body = EmptyRequest
    typealias Response = BreachesForCustomEmailResponse

    var debugDescription: String
    var path: String

    init(emailId: String) {
        debugDescription = "Get breaches for a custom email"
        path = "/pass/v1/breach/custom_email/\(emailId)/breaches"
    }
}
