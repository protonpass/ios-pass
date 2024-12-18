//
// SendUserMonitoringStatsEndpoint.swift
// Proton Pass - Created on 17/12/2024.
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

struct SendUserMonitoringStatsRequest: Encodable, Sendable {
    let reusedPasswords: Int
    let inactive2FA: Int
    let excludedItems: Int
    let weakPasswords: Int

    enum CodingKeys: String, CodingKey {
        case reusedPasswords = "ReusedPasswords"
        case inactive2FA = "Inactive2FA"
        case excludedItems = "ExcludedItems"
        case weakPasswords = "WeakPasswords"
    }
}

struct SendUserMonitoringStatsEndpoint: Endpoint {
    typealias Body = SendUserMonitoringStatsRequest
    typealias Response = CodeOnlyResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: SendUserMonitoringStatsRequest?

    init(request: SendUserMonitoringStatsRequest) {
        debugDescription = "Send user monitor stats to admin"
        path = "/pass/v1/organization/report/client_data"
        method = .post
        body = request
    }
}
