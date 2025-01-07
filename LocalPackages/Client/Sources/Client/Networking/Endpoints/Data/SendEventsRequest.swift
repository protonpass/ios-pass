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

import Entities
import Foundation

struct SendEventsRequest: Encodable, Sendable {
    let eventInfo: [EventInfo]

    enum CodingKeys: String, CodingKey {
        case eventInfo = "EventInfo"
    }
}

typealias DimensionsValue = Encodable & Sendable
struct Dimensions: Encodable, Sendable {
    var properties: [String: any DimensionsValue]

    // Custom encode function to handle dynamic keys and types
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        for (key, value) in properties {
            let codingKey = DynamicCodingKeys(stringValue: key)
            // Encode the value based on its dynamic type
            switch value {
            case let stringValue as String:
                try container.encode(stringValue, forKey: codingKey)
            case let intValue as Int:
                try container.encode(intValue, forKey: codingKey)
            case let doubleValue as Double:
                try container.encode(doubleValue, forKey: codingKey)
            case let boolValue as Bool:
                try container.encode(boolValue, forKey: codingKey)
            default:
                // Throw an error for unsupported types
                let context = EncodingError.Context(codingPath: encoder.codingPath,
                                                    debugDescription: "Unsupported type in properties")
                throw EncodingError.invalidValue(value, context)
            }
        }
    }

    // Dynamic coding keys to allow for unknown keys
    private struct DynamicCodingKeys: CodingKey {
        var intValue: Int?

        init?(intValue: Int) {
            self.intValue = intValue
            stringValue = ""
        }

        var stringValue: String

        init(stringValue: String) { self.stringValue = stringValue }
    }
}

public struct EventInfo: Encodable, Sendable {
    let measurementGroup: String
    let event: String
    // periphery:ignore
    let values: [String: String] = [:] // Not applicable to mobile apps
    let dimensions: Dimensions

    enum CodingKeys: String, CodingKey {
        case measurementGroup = "MeasurementGroup"
        case event = "Event"
        case values = "Values"
        case dimensions = "Dimensions"
    }
}

private extension TelemetryEventType {
    var extraValues: [String: DimensionsValue]? {
        switch self {
        case let .notificationDisplay(notificationKey):
            ["notificationKey": notificationKey]
        case let .notificationChangeStatus(notificationKey, notificationStatus):
            [
                "notificationKey": notificationKey,
                "notificationStatus": notificationStatus
            ]
        case let .notificationCtaClick(notificationKey):
            ["notificationKey": notificationKey]
        default:
            nil
        }
    }
}

public extension EventInfo {
    init(event: TelemetryEvent, userTier: String) {
        measurementGroup = "pass.any.user_actions"
        self.event = event.type.eventName
        var baseDimensions = [String: DimensionsValue]()
        if let dimensionType = event.dimensionType {
            baseDimensions["type"] = dimensionType
        }
        if let dimensionLocation = event.dimensionLocation {
            baseDimensions["location"] = dimensionLocation
        }
        baseDimensions["user_tier"] = userTier

        if let extraDimensionsElements = event.type.extraValues {
            baseDimensions = baseDimensions.merging(extraDimensionsElements) { current, _ in current }
        }

        dimensions = Dimensions(properties: baseDimensions)
    }
}

private extension TelemetryEvent {
    var dimensionType: String? {
        switch type {
        case let .create(itemContentType):
            itemContentType.dimensionType
        case let .read(itemContentType):
            itemContentType.dimensionType
        case let .update(itemContentType):
            itemContentType.dimensionType
        case let .delete(itemContentType):
            itemContentType.dimensionType
        case .twoFaCreation, .twoFaUpdate:
            "login"
        default:
            nil
        }
    }

    var dimensionLocation: String? {
        switch type {
        case .autofillDisplay, .autofillTriggeredFromApp:
            "app"
        case .autofillTriggeredFromSource:
            "source"
        default:
            nil
        }
    }
}

private extension ItemContentType {
    var dimensionType: String {
        switch self {
        case .login:
            "login"
        case .alias:
            "alias"
        case .note:
            "note"
        case .creditCard:
            "credit_card"
        case .identity:
            "identity"
        }
    }
}
