//
// CustomEmail.swift
// Proton Pass - Created on 10/04/2024.
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

import Foundation

public struct CustomEmail: Decodable, Equatable, Sendable, Hashable, Identifiable {
    public let customEmailID, email: String
    public let verified: Bool
    public let breachCounter: Int
    public let flags: Int
    public let lastBreachedTime: Int?

    public init(customEmailID: String,
                email: String,
                verified: Bool,
                breachCounter: Int,
                flags: Int,
                lastBreachedTime: Int?) {
        self.customEmailID = customEmailID
        self.email = email
        self.verified = verified
        self.breachCounter = breachCounter
        self.flags = flags
        self.lastBreachedTime = lastBreachedTime
    }

    public var id: String {
        customEmailID
    }

    public var isBreached: Bool {
        breachCounter > 0
    }

//    public var lastestBreachDate: String {
//        guard let lastBreachedTime else {
//            return ""
//        }
//        let date = Date(timeIntervalSince1970: TimeInterval(lastBreachedTime))
//        let dateFormatter = DateFormatter()
//
//        // Set the date and time style
//        dateFormatter.dateFormat = "MMM dd yyyy" // e.g., "Feb 14 2024, 09:41"
//
//        // Set the locale to the current device's locale
//        dateFormatter.locale = Locale.current
//
//        // Optional: If you want the time to also adapt to the user's 24-hour or 12-hour format preference:
//        dateFormatter.timeStyle = .short
//        dateFormatter.dateStyle = .medium
//        dateFormatter.setLocalizedDateFormatFromTemplate("MMM dd yyyy")
//
//        return dateFormatter.string(from: date)
//    }
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
