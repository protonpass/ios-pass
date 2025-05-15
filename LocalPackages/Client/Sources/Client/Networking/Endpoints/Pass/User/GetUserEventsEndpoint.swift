//
// GetUserEventsEndpoint.swift
// Proton Pass - Created on 15/05/2025.
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
//

import Foundation

struct GetUserEventsResponse: Decodable, Sendable {
    let events: UserEvents
}

struct GetUserEventsEndpoint: Endpoint {
    typealias Body = EmptyRequest
    typealias Response = GetPassUserInformationsResponse

    var debugDescription: String
    var path: String

    init(lastEventId: Int) {
        debugDescription = "Get user events since a given eventID"
        path = "/pass/v1/user/sync_event/\(lastEventId)"
    }
}
