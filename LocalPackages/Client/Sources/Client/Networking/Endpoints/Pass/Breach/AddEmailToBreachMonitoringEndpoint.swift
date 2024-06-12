//
// AddEmailToBreachMonitoringEndpoint.swift
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

struct AddEmailToBreachMonitoringResponse: Decodable, Equatable, Sendable {
    let email: CustomEmail
}

struct AddEmailToBreachMonitoringRequest: Encodable, Sendable {
    let email: String

    enum CodingKeys: String, CodingKey {
        case email = "Email"
    }
}

struct AddEmailToBreachMonitoringEndpoint: Endpoint {
    typealias Body = AddEmailToBreachMonitoringRequest
    typealias Response = AddEmailToBreachMonitoringResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: AddEmailToBreachMonitoringRequest?

    init(request: AddEmailToBreachMonitoringRequest) {
        debugDescription = "Add an email to monitor for breaches"
        path = "/pass/v1/breach/custom_email"
        method = .post
        body = request
    }
}
