//
// SearchSelection.swift
// Proton Pass - Created on 30/11/2023.
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

public enum SearchMode: Equatable, Hashable, Sendable {
    case pinned
    case all(VaultSelection)

    public var vaultSelection: VaultSelection? {
        switch self {
        case let .all(selection):
            selection
        default:
            nil
        }
    }

    public var isSpecificSelection: Bool {
        if let selection = vaultSelection, selection != .all {
            return true
        }
        return false
    }
}
