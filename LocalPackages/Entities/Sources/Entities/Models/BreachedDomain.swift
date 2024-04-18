//
// BreachedDomain.swift
// Proton Pass - Created on 15/04/2024.
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

public struct BreachedDomain: Decodable, Equatable, Sendable, Comparable {
    public let domain: String
    public let breachTime: Int

    public init(domain: String, breachTime: Int) {
        self.domain = domain
        self.breachTime = breachTime
    }

    public static func < (lhs: BreachedDomain, rhs: BreachedDomain) -> Bool {
        lhs.breachTime < rhs.breachTime
    }

    public var formattedDateDescription: String {
        let date = Date(timeIntervalSince1970: TimeInterval(breachTime))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM dd, yyyy" // e.g., "Apr 21, 2023"
        dateFormatter.locale = Locale.current
        return dateFormatter.string(from: date)
    }
}
