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

public struct TelemetryEvent {
    public let uuid: String
    public let time: TimeInterval
    public let type: TelemetryEventType
}

public enum TelemetryEventType {
    case create(ItemContentType)
    case read(ItemContentType)
    case update(ItemContentType)
    case delete(ItemContentType)
    case autofillDisplay
    case autofillTriggeredFromSource // AutoFill from QuickType bar
    case autofillTriggeredFromApp // AutoFill manually from extension
    case searchTriggered
    case searchClick

    public var rawValue: String {
        switch self {
        case .create(let type):
            return "create.\(type.rawValue)"
        case .read(let type):
            return "read.\(type.rawValue)"
        case .update(let type):
            return "update.\(type.rawValue)"
        case .delete(let type):
            return "delete.\(type.rawValue)"
        case .autofillDisplay:
            return "autofill.display"
        case .autofillTriggeredFromSource:
            return "autofill.triggered.source"
        case .autofillTriggeredFromApp:
            return "autofill.triggered.app"
        case .searchTriggered:
            return "search.triggered"
        case .searchClick:
            return "search.click"
        }
    }

    init?(rawValue: String) {
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
            return lhsType == rhsType
        case let (.read(lhsType), .read(rhsType)):
            return lhsType == rhsType
        case let (.update(lhsType), .update(rhsType)):
            return lhsType == rhsType
        case let (.delete(lhsType), .delete(rhsType)):
            return lhsType == rhsType
        case (.autofillDisplay, .autofillDisplay),
            (.autofillTriggeredFromSource, .autofillTriggeredFromSource),
            (.autofillTriggeredFromApp, .autofillTriggeredFromApp),
            (.searchTriggered, .searchTriggered),
            (.searchClick, .searchClick):
            return true
        default:
            return false
        }
    }
}
