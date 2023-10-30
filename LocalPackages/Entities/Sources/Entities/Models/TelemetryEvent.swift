//
// TelemetryEvent.swift
// Proton Pass - Created on 19/04/2023.
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

public struct TelemetryEvent: Sendable {
    public let uuid: String
    public let time: TimeInterval
    public let type: TelemetryEventType

    public init(uuid: String, time: TimeInterval, type: TelemetryEventType) {
        self.uuid = uuid
        self.time = time
        self.type = type
    }
}

public enum TelemetryEventType: Sendable {
    case create(ItemContentType)
    case read(ItemContentType)
    case update(ItemContentType)
    case delete(ItemContentType)
    case autofillDisplay
    case autofillTriggeredFromSource // AutoFill from QuickType bar
    case autofillTriggeredFromApp // AutoFill manually from extension
    case searchTriggered
    case searchClick
    case twoFaCreation
    case twoFaUpdate

    public var rawValue: String {
        switch self {
        case let .create(type):
            "create.\(type.rawValue)"
        case let .read(type):
            "read.\(type.rawValue)"
        case let .update(type):
            "update.\(type.rawValue)"
        case let .delete(type):
            "delete.\(type.rawValue)"
        case .autofillDisplay:
            "autofill.display"
        case .autofillTriggeredFromSource:
            "autofill.triggered.source"
        case .autofillTriggeredFromApp:
            "autofill.triggered.app"
        case .searchTriggered:
            "search.triggered"
        case .searchClick:
            "search.click"
        case .twoFaCreation:
            "2fa.creation"
        case .twoFaUpdate:
            "2fa.update"
        }
    }

    public init?(rawValue: String) {
        switch rawValue {
        case "autofill.display":
            self = .autofillDisplay
        case "autofill.triggered.source":
            self = .autofillTriggeredFromSource
        case "autofill.triggered.app":
            self = .autofillTriggeredFromApp
        case "search.triggered":
            self = .searchTriggered
        case "search.click":
            self = .searchClick
        case "2fa.creation":
            self = .twoFaCreation
        case "2fa.update":
            self = .twoFaUpdate
        default:
            if let crudEvent = Self.crudEvent(rawValue: rawValue) {
                self = crudEvent
            } else {
                return nil
            }
        }
    }

    private static func crudEvent(rawValue: String) -> TelemetryEventType? {
        let components = rawValue.components(separatedBy: ".")
        guard components.count == 2,
              let eventType = components.first,
              let itemTypeRawValue = Int(components.last ?? ""),
              let itemType = ItemContentType(rawValue: itemTypeRawValue) else { return nil }

        switch eventType {
        case "create":
            return .create(itemType)
        case "read":
            return .read(itemType)
        case "update":
            return .update(itemType)
        case "delete":
            return .delete(itemType)
        default:
            return nil
        }
    }
}

extension TelemetryEventType: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.create(lhsType), .create(rhsType)):
            lhsType == rhsType
        case let (.read(lhsType), .read(rhsType)):
            lhsType == rhsType
        case let (.update(lhsType), .update(rhsType)):
            lhsType == rhsType
        case let (.delete(lhsType), .delete(rhsType)):
            lhsType == rhsType
        case (.autofillDisplay, .autofillDisplay),
             (.autofillTriggeredFromApp, .autofillTriggeredFromApp),
             (.autofillTriggeredFromSource, .autofillTriggeredFromSource),
             (.searchClick, .searchClick),
             (.searchTriggered, .searchTriggered),
             (.twoFaCreation, .twoFaCreation),
             (.twoFaUpdate, .twoFaUpdate):
            true
        default:
            false
        }
    }
}
