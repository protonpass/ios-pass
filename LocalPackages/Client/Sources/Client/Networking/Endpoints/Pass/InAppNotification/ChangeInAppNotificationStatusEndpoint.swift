//
// ChangeInAppNotificationStatusEndpoint.swift
// Proton Pass - Created on 05/11/2024.
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

struct ChangeInAppNotificationStatusRequest: Encodable, Sendable {
    let status: Int

    enum CodingKeys: String, CodingKey {
        case status = "Status"
    }
}

struct ChangeInAppNotificationStatusEndpoint: Endpoint, @unchecked Sendable {
    typealias Body = ChangeInAppNotificationStatusRequest
    typealias Response = CodeOnlyResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: ChangeInAppNotificationStatusRequest?

    init(notificationId: String, status: Int) {
        debugDescription = "Change notification status"
        path = "/pass/v1/notification/\(notificationId)"
        method = .put
        body = .init(status: status)
    }
}
