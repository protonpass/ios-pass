//
// AppLockTime.swift
// Proton Pass - Created on 19/03/2024.
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

import Foundation

public enum AppLockTime: Int, Codable, CaseIterable, Sendable {
    case immediately = 0
    case oneMinute = 1
    case twoMinutes = 2
    case fiveMinutes = 3
    case tenMinutes = 4
    case oneHour = 5
    case fourHours = 6

    public static var `default`: Self { .twoMinutes }

    public var intervalInMinutes: Int {
        switch self {
        case .immediately:
            0
        case .oneMinute:
            1
        case .twoMinutes:
            2
        case .fiveMinutes:
            5
        case .tenMinutes:
            10
        case .oneHour:
            60
        case .fourHours:
            240
        }
    }

    public init?(rawValue: Int) {
        self = switch rawValue {
        case 0:
            .immediately
        case 1:
            .oneMinute
        case 2:
            .twoMinutes
        case 3:
            .fiveMinutes
        case 4:
            .tenMinutes
        case 5:
            .oneHour
        case 6:
            .fourHours
        case 7:
            // Deprecated "Never" case
            .default
        default:
            .default
        }
    }
}
