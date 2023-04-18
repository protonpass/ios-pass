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

struct TelemetryEvent {
    let uuid: String
    let type: TelemetryEventType
}

enum TelemetryEventType {
    case create(ItemContentType)
    case read(ItemContentType)
    case update(ItemContentType)
    case delete(ItemContentType)

    var rawValue: String {
        switch self {
        case .create(let type):
            return "create.\(type.rawValue)"
        case .read(let type):
            return "read.\(type.rawValue)"
        case .update(let type):
            return "update.\(type.rawValue)"
        case .delete(let type):
            return "delete.\(type.rawValue)"
        }
    }

    init?(rawValue: String) {
        let components = rawValue.components(separatedBy: ".")
        guard components.count == 2,
              let eventType = components.first,
              let itemTypeRawValue = Int(components.last ?? ""),
              let itemType = ItemContentType(rawValue: itemTypeRawValue) else { return nil }

        switch eventType {
        case "create":
            self = .create(itemType)
        case "read":
            self = .read(itemType)
        case "update":
            self = .update(itemType)
        case "delete":
            self = .delete(itemType)
        default:
            return nil
        }
    }
}

extension TelemetryEventType: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.create(lhsType), .create(rhsType)):
            return lhsType == rhsType
        case let (.read(lhsType), .read(rhsType)):
            return lhsType == rhsType
        case let (.update(lhsType), .update(rhsType)):
            return lhsType == rhsType
        case let (.delete(lhsType), .delete(rhsType)):
            return lhsType == rhsType
        default:
            return false
        }
    }
}
