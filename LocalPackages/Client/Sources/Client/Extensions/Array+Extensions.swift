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

import Entities

// periphery:ignore
public struct WritableOldestVaults {
    public let owned: Vault?
    public let other: Vault?

    static var empty: WritableOldestVaults {
        WritableOldestVaults(owned: nil, other: nil)
    }

    public func isOneOf(shareId: String) -> Bool {
        shareId == owned?.shareId || shareId == other?.shareId
    }
}

public extension [Vault] {
    /// This return the 2 oldest vaults to witch the users has write value.
    /// The first vault always belongs the the current user
    var twoOldestVaults: WritableOldestVaults {
        if self.isEmpty {
            return WritableOldestVaults.empty
        }
        var oldestOwned: Vault?
        var secondOldest: Vault?
        for vault in self {
            if oldestOwned == nil, vault.isOwner {
                oldestOwned = vault
            } else {
                if let previousOldestOwned = oldestOwned,
                   vault.isOwner,
                   previousOldestOwned.createTime > vault.createTime {
                    secondOldest = oldestOwned
                    oldestOwned = vault
                } else {
                    if secondOldest == nil {
                        secondOldest = vault
                    } else if let previousSecondOldest = secondOldest,
                              previousSecondOldest.createTime > vault.createTime {
                        secondOldest = vault
                    }
                }
            }
        }
        return WritableOldestVaults(owned: oldestOwned, other: secondOldest)
    }

    var oldestOwned: Vault? {
        if self.isEmpty {
            return nil
        }
        return self.filter(\.isOwner).min(by: { $0.createTime < $1.createTime })
    }

    var numberOfOwnedVault: Int {
        self.filter(\.isOwner).count
    }
}
