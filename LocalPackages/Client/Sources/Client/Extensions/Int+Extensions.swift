//
// Int+Extensions.swift
// Proton Pass - Created on 25/01/2024.
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

public extension BinaryInteger {
    var codableBoolValue: Bool {
        self != 0
    }

    var nilIfZero: Int? {
        self == 0 ? nil : Int(self)
    }

    var fullDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        let relativeDateFormatter = RelativeDateTimeFormatter()

        let timeInterval = TimeInterval(self)
        let date = Date(timeIntervalSince1970: timeInterval)
        let dateString = dateFormatter.string(from: date)
        let relativeString = relativeDateFormatter.localizedString(for: date, relativeTo: .now)
        return "\(dateString) (\(relativeString))"
    }

    var shortDateString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM-dd-yy HH:mm"
        let timeInterval = TimeInterval(self)
        let date = Date(timeIntervalSince1970: timeInterval)
        return dateFormatter.string(from: date)
    }
}
