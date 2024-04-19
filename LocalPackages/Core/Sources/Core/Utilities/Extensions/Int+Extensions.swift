//
// Int+Extensions.swift
// Proton Pass - Created on 19/04/2024.
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

import Entities

public extension Int {
    func isFlagActive(_ flag: ItemFlags) -> Bool {
        (self & flag.intValue) != 0
    }

    // periphery:ignore
    func areAllFlagsActive(_ flagsToCheck: [ItemFlags]) -> Bool {
        for flag in flagsToCheck where (self & flag.intValue) == 0 {
            return false // If any flag is not set, return false
        }
        return true // All flags are set
    }

    // periphery:ignore
    func isAnyFlagActive(_ flagsToCheck: [ItemFlags]) -> Bool {
        for flag in flagsToCheck where (self & flag.intValue) != 0 {
            return true // If any flag is set, return true
        }
        return false // No flags are set
    }
}
