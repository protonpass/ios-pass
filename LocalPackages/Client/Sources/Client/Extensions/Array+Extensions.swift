//
// Array+Extensions.swift
// Proton Pass - Created on 05/10/2023.
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

public extension [Vault] {
    var twoOldestVaults: (oldestOwned: Vault?, secondOldest: Vault?) {
        if self.isEmpty {
            return (oldestOwned: nil, secondOldest: nil)
        }
        var oldestOwned: Vault?
        var secondOldest: Vault?
        for vault in self {
            if oldestOwned == nil, vault.isOwner {
                oldestOwned = vault
            } else {
                if var oldestOwned,
                   vault.isOwner,
                   oldestOwned.createTime > vault.createTime {
                    secondOldest = oldestOwned
                    oldestOwned = vault
                } else {
                    if secondOldest == nil {
                        secondOldest = vault
                    } else if var secondOldest,
                              secondOldest.createTime > vault.createTime {
                        secondOldest = vault
                    }
                }
            }
        }
        return (oldestOwned: oldestOwned, secondOldest: secondOldest)
    }
}
