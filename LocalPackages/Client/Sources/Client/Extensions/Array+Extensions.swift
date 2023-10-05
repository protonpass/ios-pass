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
    var twoOldestVaults: (oldest: Vault?, secondOldest: Vault?) {
        if self.isEmpty {
            return (oldest: nil, secondOldest: nil)
        }
        var oldest: Vault?
        var secondOldest: Vault?
        for vault in self {
            if oldest == nil {
                oldest = vault
            } else {
                if var oldest,
                   oldest.createTime > vault.createTime {
                    secondOldest = oldest
                    oldest = vault
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
        return (oldest: oldest, secondOldest: secondOldest)
    }
}
