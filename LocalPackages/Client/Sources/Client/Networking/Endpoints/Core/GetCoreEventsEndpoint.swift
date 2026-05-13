//
// GetCoreEventsEndpoint.swift
// Proton Pass - Created on 12/05/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import Foundation
import ProtonCoreNetworking

public struct CoreEvents: Decodable, Sendable {
    enum Action: Int, Decodable {
        case delete = 0
        case create
        case update
        case updateFlags
    }

    struct Event: Decodable {
        let action: Action
    }

    let users: [Event]?
    let addresses: [Event]?
}

struct GetCoreEventsEndpoint: Endpoint {
    typealias Body = EmptyRequest
    typealias Response = CoreEvents

    var debugDescription: String
    var path: String

    init(lastEventId: String) {
        debugDescription = "Get core events"
        path = "/core/v6/events/\(lastEventId)"
    }
}
