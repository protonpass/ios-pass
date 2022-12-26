//
// ClipboardExpiration.swift
// Proton Pass - Created on 26/12/2022.
// Copyright (c) 2022 Proton Technologies AG
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

public enum ClipboardExpiration: Int, CustomStringConvertible, CaseIterable {
    case never = 0
    case thirtySeconds = 1
    case fortyFiveSeconds = 2
    case sixtySeconds = 3

    public var description: String {
        switch self {
        case .never:
            return "Never"
        case .thirtySeconds:
            return "30 seconds"
        case .fortyFiveSeconds:
            return "45 seconds"
        case .sixtySeconds:
            return "60 seconds"
        }
    }

    public var expirationDate: Date? {
        switch self {
        case .never:
            return nil
        case .thirtySeconds:
            return Date().addingTimeInterval(30)
        case .fortyFiveSeconds:
            return Date().addingTimeInterval(45)
        case .sixtySeconds:
            return Date().addingTimeInterval(60)
        }
    }
}
