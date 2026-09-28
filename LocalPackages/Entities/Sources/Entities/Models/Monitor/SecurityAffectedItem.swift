//
// SecurityAffectedItem.swift
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

public struct SecurityAffectedItem: Sendable {
    public let item: SymmetricallyEncryptedItem

    public var id: String {
        item.itemId + item.shareId
    }

    /// Weaknesses genuinely detected on the item, IGNORING any per-check suppression or full
    /// exclusion.
    public let detected: Set<WeaknessKind>
    public let display: ItemUiModel

    /// Items sharing a password get the same value; nil when the password isn't reused. Only
    /// comparable within a single refresh, and carries nothing derived from the password.
    public let reuseGroup: Int?

    public init(item: SymmetricallyEncryptedItem,
                detected: Set<WeaknessKind>,
                display: ItemUiModel,
                reuseGroup: Int?) {
        self.item = item
        self.detected = detected
        self.display = display
        self.reuseGroup = reuseGroup
    }
}

public extension SecurityAffectedItem {
    var suppressedChecks: Set<WeaknessKind> {
        item.item.suppressedChecks
    }

    var isFullyExcluded: Bool {
        item.item.monitoringDisabled
    }

    var activeWeaknesses: Set<WeaknessKind> {
        isFullyExcluded ? [] : detected.subtracting(suppressedChecks)
    }

    var isExcludedItem: Bool {
        item.item.isExcludedItem
    }

    var shouldBeIncluded: Bool {
        !detected.isEmpty || isExcludedItem
    }
}
