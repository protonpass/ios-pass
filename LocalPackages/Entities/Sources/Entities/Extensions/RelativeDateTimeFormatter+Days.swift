//
// RelativeDateTimeFormatter+Days.swift
// Proton Pass - Created on 29/10/2026.
// Copyright (c) 2026 Proton Technologies AG
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

public extension RelativeDateTimeFormatter {
    /// Same as `localizedString(for:relativeTo:)` but keeps durations of up to 14 days in days.
    /// Because the system rounds down to the largest unit, so 13.9 days becomes "in 1 week".
    /// We want to show "in 13 days" instead
    func localizedStringPreferringDays(for date: Date, relativeTo referenceDate: Date) -> String {
        let days = date.timeIntervalSince(referenceDate) / 86_400
        let roundedDays = days.rounded()
        guard days >= 1, roundedDays <= 14 else {
            return localizedString(for: date, relativeTo: referenceDate)
        }
        return localizedString(from: DateComponents(day: Int(roundedDays)))
    }
}
