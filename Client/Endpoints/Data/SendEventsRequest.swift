//
// SendEventsRequest.swift
// Proton Pass - Created on 17/04/2023.
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

import Foundation

struct SendEventsRequest: Encodable {
    let eventInfo: [EventInfo]

    enum CodingKeys: String, CodingKey {
        case eventInfo = "EventInfo"
    }
}

public struct EventInfo: Encodable {
    let measurementGroup: String
    let event: String
    let dimensions: Dimensions

    enum CodingKeys: String, CodingKey {
        case measurementGroup = "MeasurementGroup"
        case event = "Event"
        case dimensions = "Dimensions"
    }

    struct Dimensions: Encodable {
        let type: String
        let userTier: String

        enum CodingKeys: String, CodingKey {
            case type = "type"
            case userTier = "user_tier"
        }

        init(type: String, userTier: String) {
            self.type = type
            self.userTier = userTier
        }
    }

    init(measurementGroup: String, event: String, dimensions: Dimensions) {
        self.measurementGroup = measurementGroup
        self.event = event
        self.dimensions = dimensions
    }
}

public extension EventInfo {
    init(event: TelemetryEvent, planName: String) {
        self.measurementGroup = "pass.ios.user_actions"
        self.event = event.eventName
        self.dimensions = .init(type: event.itemContentType.dimensionType, userTier: planName)
    }
}

private extension TelemetryEvent {
    var eventName: String {
        switch type {
        case .create:
            return "item.creation"
        case .read:
            return "item.read"
        case .update:
            return "item.update"
        case .delete:
            return "item.deletion"
        }
    }

    var itemContentType: ItemContentType {
        switch type {
        case .create(let type):
            return type
        case .read(let type):
            return type
        case .update(let type):
            return type
        case .delete(let type):
            return type
        }
    }
}

private extension ItemContentType {
    var dimensionType: String {
        switch self {
        case .login:
            return "login"
        case .alias:
            return "alias"
        case .note:
            return "note"
        }
    }
}
