//
// SendItemReadEventsEndpoint.swift
// Proton Pass - Created on 10/06/2024.
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

import Entities
import Foundation
import ProtonCoreNetworking

struct ItemTime: Sendable, Encodable {
    let itemID: String
    let timestamp: Int
}

struct SendItemReadEventsRequest: Sendable, Encodable {
    let itemTimes: [ItemTime]
}

struct SendItemReadEventsEndpoint: Endpoint {
    typealias Body = SendItemReadEventsRequest
    typealias Response = PinItemResponse

    var debugDescription: String
    var path: String
    var method: HTTPMethod
    var body: SendItemReadEventsRequest?

    init(events: [ItemReadEvent], shareId: String) {
        debugDescription = "Send item read events (B2B only)"
        path = "/pass/v1/share/\(shareId)/item/read"
        method = .put
        body = .init(itemTimes: events.map { $0.toItemTime() })
    }
}

private extension ItemReadEvent {
    func toItemTime() -> ItemTime {
        .init(itemID: itemId, timestamp: Int(timestamp))
    }
}
