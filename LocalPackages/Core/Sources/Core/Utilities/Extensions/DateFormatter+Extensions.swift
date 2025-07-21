//
// DateFormatter+Extensions.swift
// Proton Pass - Created on 11/06/2025.
// Copyright (c) 2025 Proton Technologies AG
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

// periphery:ignore:all
import Foundation

public extension DateFormatter {
    convenience init(format: String,
                     locale: Locale = .current,
                     timeStyle: DateFormatter.Style = .short,
                     dateStyle: DateFormatter.Style = .medium) {
        self.init()
        dateFormat = format
        self.locale = locale
        self.timeStyle = timeStyle
        self.dateStyle = dateStyle
        setLocalizedDateFormatFromTemplate(format)
    }

    static var fullDateNoTime: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }

    static var timestampCustomField: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = .init(identifier: "UTC")
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }
}
