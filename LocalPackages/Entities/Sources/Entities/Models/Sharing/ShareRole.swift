//
// ShareRole.swift
// Proton Pass - Created on 20/07/2023.
// Copyright (c) 2023 Proton Technologies AG
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

public enum ShareRole: String, CaseIterable, Equatable, Sendable, Comparable {
    /// Administrator
    case admin = "1"
    /// Full write permission. They can do anything an admin can do except manage membership and invite users.
    case write = "2"
    /// Read only. Can only read the contents of a share. They can update the last used time for themselves.
    case read = "3"

    public static func < (lhs: ShareRole, rhs: ShareRole) -> Bool {
        lhs.weight < rhs.weight
    }
}

private extension ShareRole {
    // Used for comparison
    var weight: Int {
        switch self {
        case .admin: 3
        case .write: 2
        case .read: 1
        }
    }
}
