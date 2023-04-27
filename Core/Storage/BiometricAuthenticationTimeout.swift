//
// BiometricAuthenticationTimeout.swift
// Proton Pass - Created on 27/04/2023.
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

public enum BiometricAuthenticationTimeout: Int, CustomStringConvertible, CaseIterable {
    case immediately = 0
    case oneMinute = 1
    case twoMinutes = 2
    case fiveMinutes = 3
    case tenMinutes = 4
    case oneHour = 5
    case fourHours = 6
    case never = 7

    public var description: String {
        switch self {
        case .immediately:
            return "Immediately"
        case .oneMinute:
            return "After 1 minute"
        case .twoMinutes:
            return "After 2 minutes"
        case .fiveMinutes:
            return "After 5 minutes"
        case .tenMinutes:
            return "After 10 minutes"
        case .oneHour:
            return "After 1 hour"
        case .fourHours:
            return "After 4 hours"
        case .never:
            return "Never"
        }
    }

    /// Calculate the next moment that users need to authenticate from the given `currentDate`
    /// - Returns: `nil` if not applicable because `never`
    public func nextThreshold(currentDate: Date) -> Date? {
        switch self {
        case .immediately:
            return currentDate
        case .oneMinute:
            return currentDate.addingTimeInterval(60)
        case .twoMinutes:
            return currentDate.addingTimeInterval(120)
        case .fiveMinutes:
            return currentDate.addingTimeInterval(300)
        case .tenMinutes:
            return currentDate.addingTimeInterval(600)
        case .oneHour:
            return currentDate.addingTimeInterval(3_600)
        case .fourHours:
            return currentDate.addingTimeInterval(4 * 3_600)
        case .never:
            return nil
        }
    }
}
