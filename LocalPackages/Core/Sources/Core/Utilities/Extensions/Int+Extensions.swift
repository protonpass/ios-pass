//
// Int+Extensions.swift
// Proton Pass - Created on 19/04/2024.
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

import Entities
import Foundation

public extension Int {
    func isFlagActive(_ flag: ItemFlags) -> Bool {
        (self & flag.intValue) != 0
    }

    // periphery:ignore
    func areAllFlagsActive(_ flagsToCheck: [ItemFlags]) -> Bool {
        for flag in flagsToCheck where (self & flag.intValue) == 0 {
            return false // If any flag is not set, return false
        }
        return true // All flags are set
    }

    // periphery:ignore
    func isAnyFlagActive(_ flagsToCheck: [ItemFlags]) -> Bool {
        for flag in flagsToCheck where (self & flag.intValue) != 0 {
            return true // If any flag is set, return true
        }
        return false // No flags are set
    }
}

public extension Int {
    var lastestBreachDate: String {
        let date = Date(timeIntervalSince1970: TimeInterval(self))
        let dateFormatter = DateFormatter()

        // Set the date and time style
        dateFormatter.dateFormat = "MMM dd yyyy" // e.g., "Feb 14 2024, 09:41"

        // Set the locale to the current device's locale
        dateFormatter.locale = Locale.current

        // Optional: If you want the time to also adapt to the user's 24-hour or 12-hour format preference:
        dateFormatter.timeStyle = .short
        dateFormatter.dateStyle = .medium
        dateFormatter.setLocalizedDateFormatFromTemplate("MMM dd yyyy")

        return dateFormatter.string(from: date)
    }
}
