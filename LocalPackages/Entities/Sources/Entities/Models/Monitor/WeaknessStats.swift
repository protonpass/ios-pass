//
// WeaknessStats.swift
// Proton Pass - Created on 08/03/2024.
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

public struct WeaknessStats: Equatable, Sendable {
    private let counts: [WeaknessKind: Int]

    /// Items in the "Excluded items" bucket. This is a monitoring-status count, not a weakness,
    /// so it stays separate from `counts`.
    public let excludedItems: Int

    public init(counts: [WeaknessKind: Int], excludedItems: Int) {
        self.counts = counts
        self.excludedItems = excludedItems
    }

    public func count(for kind: WeaknessKind) -> Int {
        counts[kind] ?? 0
    }

    public var hasWeakOrReusedPasswords: Bool {
        (count(for: .weakPassword) + count(for: .reusedPassword)) > 0
    }
}
