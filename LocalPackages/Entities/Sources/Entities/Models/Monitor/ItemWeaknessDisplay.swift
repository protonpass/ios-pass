//
// ItemWeaknessDisplay.swift
// Proton Pass - Created on 16/06/2026.
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

/// A login-detail row: one `WeaknessKind` (and whether that check is excluded) or the fully excluded state.
/// Dark Web Monitoring has its own route.
public enum ItemWeaknessDisplay: Identifiable, Hashable {
    case weakness(WeaknessKind, isExcluded: Bool)
    case fullyExcluded

    public var id: Self {
        self
    }

    public var isExcluded: Bool {
        switch self {
        case let .weakness(_, isExcluded):
            isExcluded

        case .fullyExcluded:
            true
        }
    }

    public var isReusedPasswordWeakness: Bool {
        if case let .weakness(weakness, _) = self {
            weakness == .reusedPassword
        } else {
            false
        }
    }
}
