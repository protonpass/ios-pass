//
// WeaknessKind.swift
// Proton Pass - Created on 15/06/2026.
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

/// A per-item security weakness Pass Monitor can detect.
///
/// Single source of truth for weakness identity, display ordering and the per-check
/// exclusion flag. Unlike a breach (an account/email-level concern surfaced via Dark Web
/// Monitoring), every `WeaknessKind` is item-scoped and individually excludable.
public enum WeaknessKind: Sendable, Hashable, CaseIterable, Identifiable, Comparable {
    case weakPassword
    case compromisedPassword
    case reusedPassword
    case missing2FA

    public var id: Self {
        self
    }

    /// Product-defined display order — lower value is shown first / treated as higher priority.
    /// Defined explicitly (not via declaration order) so reordering the cases cannot silently
    /// change the ordering; pinned by `WeaknessKindTests`.
    /// Compromised passwords are surfaced as a paid feature directly below reused passwords.
    public var displayPriority: Int {
        switch self {
        case .weakPassword: 0
        case .reusedPassword: 1
        case .compromisedPassword: 2
        case .missing2FA: 3
        }
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.displayPriority < rhs.displayPriority
    }

    /// The item flag whose presence means "skip this check for this item".
    public var skipFlag: ItemFlags {
        switch self {
        case .weakPassword: .skipWeakPasswordCheck
        case .compromisedPassword: .skipCompromisedPasswordCheck
        case .reusedPassword: .skipReusedPasswordCheck
        case .missing2FA: .skip2FACheck
        }
    }
}
