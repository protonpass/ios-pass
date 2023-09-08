//
// AppLockTime.swift
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

public enum AppLockTime: Int, Codable, CustomStringConvertible, CaseIterable {
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
            return "Immediately".localized
        case .oneMinute:
            return "After 1 minute".localized
        case .twoMinutes:
            return "After 2 minutes".localized
        case .fiveMinutes:
            return "After 5 minutes".localized
        case .tenMinutes:
            return "After 10 minutes".localized
        case .oneHour:
            return "After 1 hour".localized
        case .fourHours:
            return "After 4 hours".localized
        case .never:
            return "Never".localized
        }
    }

    public var intervalInMinutes: Int? {
        switch self {
        case .immediately:
            return 0
        case .oneMinute:
            return 1
        case .twoMinutes:
            return 2
        case .fiveMinutes:
            return 5
        case .tenMinutes:
            return 10
        case .oneHour:
            return 60
        case .fourHours:
            return 240
        case .never:
            return nil
        }
    }
}
