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

    /// Weaknesses genuinely detected on the item, IGNORING any per-check suppression or full
    /// exclusion. Suppression is applied via the computed `activeWeaknesses` below so that the
    /// "is this item weak?" and "is this check enabled?" questions stay independent.
    public let detected: Set<WeaknessKind>

    /// Display projection built once (at detection time) so consumers never re-decrypt the item.
    public let display: ItemUiModel

    /// Stable equality token for reuse grouping (a hash of the password; nil when empty). Lets the
    /// reused-password list group items without re-decrypting or holding plaintext passwords.
    public let reuseToken: String?

    public init(item: SymmetricallyEncryptedItem,
                detected: Set<WeaknessKind>,
                display: ItemUiModel,
                reuseToken: String?) {
        self.item = item
        self.detected = detected
        self.display = display
        self.reuseToken = reuseToken
    }
}

public extension SecurityAffectedItem {
    /// Checks the user has individually suppressed for this item (derived from its flags).
    var suppressedChecks: Set<WeaknessKind> {
        Set(WeaknessKind.allCases.filter { item.item.itemFlags.contains($0.skipFlag) })
    }

    /// Whether the whole item is excluded from monitoring (the `monitoringDisabled` master switch).
    var isFullyExcluded: Bool {
        item.item.monitoringDisabled
    }

    /// Weaknesses that should raise an active alert: detected, minus per-check suppressions.
    /// A fully-excluded item (`monitoringDisabled`) surfaces NO active weaknesses — full exclusion
    /// takes precedence over surfacing individual weaknesses, so the item appears only in the
    /// "Excluded items" list, never in the active weak/reused/2FA lists (IDTEAM-5965).
    var activeWeaknesses: Set<WeaknessKind> {
        isFullyExcluded ? [] : detected.subtracting(suppressedChecks)
    }

    /// Whether the item belongs in the "Excluded items" list: fully excluded, or any check skipped.
    var isExcludedItem: Bool {
        isFullyExcluded || !suppressedChecks.isEmpty
    }
}
