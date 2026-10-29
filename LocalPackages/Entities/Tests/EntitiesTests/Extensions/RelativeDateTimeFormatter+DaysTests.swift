//
// RelativeDateTimeFormatter+DaysTests.swift
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

import Entities
import Foundation
import Testing

@Suite(.tags(.extension))
struct RelativeDateTimeFormatterDaysTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let formatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.unitsStyle = .full
        return formatter
    }()

    @Test(arguments: [
        (14 * 86_400 - 5, "in 14 days"),
        (14 * 86_400 + 3_600, "in 14 days"),
        (7 * 86_400, "in 7 days"),
        (2 * 86_400 - 60, "in 2 days"),
        (86_400, "in 1 day")
    ] as [(TimeInterval, String)])
    func `durations of up to 14 days are shown in days`(interval: TimeInterval, expected: String) {
        let result = formatter.localizedStringPreferringDays(for: now.addingTimeInterval(interval),
                                                             relativeTo: now)

        #expect(result == expected)
    }

    @Test(arguments: [
        12 * 3_600,
        15 * 86_400,
        30 * 86_400 - 5,
        -2 * 86_400
    ] as [TimeInterval])
    func `durations outside 1 to 14 days fall back to the system format`(interval: TimeInterval) {
        let date = now.addingTimeInterval(interval)

        let result = formatter.localizedStringPreferringDays(for: date, relativeTo: now)

        #expect(result == formatter.localizedString(for: date, relativeTo: now))
    }
}
